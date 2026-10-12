// Responsive audit: renders EVERY screen of the app on a matrix of real-world
// phone sizes × text scales × languages (EN LTR / AR RTL) and fails on any
// layout error (RenderFlex overflow, unbounded constraints, …).
//
// Real fonts are loaded (Windows Arial / Flutter's bundled Roboto) instead of
// the square test glyphs, and the largest text scale is tested slightly above
// the app clamp (1.3) to cover width differences with Plus Jakarta Sans/Cairo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/models/onboarding_quiz_option_model.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/manager/onboarding_cubit.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/OnboardingView.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/manager/sink_unlock_cubit.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/views/SinkUnlockView.dart';
import 'package:sinkly/core/models/blockable_app_model.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/app_router.dart';
import 'package:sinkly/core/utils/service_locator.dart';
import 'package:sinkly/main.dart';

class _Device {
  const _Device(this.name, this.size, {this.top = 24, this.bottom = 24});
  final String name;
  final Size size;
  final double top;
  final double bottom;
}

const _devices = [
  // Android "Display size: Largest" / compact phones end up ~320 dp wide.
  _Device('compact-320x640', Size(320, 640)),
  _Device('android-360x720', Size(360, 720)),
  _Device('iphoneSE-375x667', Size(375, 667), top: 20, bottom: 0),
  _Device('iphone15-393x852', Size(393, 852), top: 59, bottom: 34),
  _Device('promax-430x932', Size(430, 932), top: 59, bottom: 34),
];

const _textScales = [1.0, 1.4];
const _languages = ['en', 'ar'];

Future<void> _loadRealFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var added = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      added = true;
    }
    if (added) await loader.load();
  }

  const windowsFonts = r'C:\Windows\Fonts';
  final latinAndArabic = ['$windowsFonts\\arial.ttf', '$windowsFonts\\arialbd.ttf'];
  // google_fonts styles fall back to the plain family name when the variant
  // can't be fetched → load real metrics under those names.
  for (final family in ['PlusJakartaSans', 'Cairo', 'Roboto']) {
    await load(family, latinAndArabic);
  }
}

void main() {
  late List<String> failures;
  late String currentLabel;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  for (final language in _languages) {
    for (final device in _devices) {
      for (final scale in _textScales) {
        testWidgets('layout · $language · ${device.name} · text×$scale', (tester) async {
          failures = [];
          currentLabel = 'boot';
          tester.view
            ..devicePixelRatio = 2
            ..physicalSize = device.size * 2
            ..padding = FakeViewPadding(top: device.top * 2, bottom: device.bottom * 2);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearAllTestValues();
          });

          final previousOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final message = details.exceptionAsString();
            // Missing network fonts are expected in tests (fetching disabled).
            if (message.contains('google_fonts') || message.contains('GoogleFonts')) return;
            final text = details.toString();
            final source = RegExp(r'(lib/[^\s:]+\.dart:\d+)').firstMatch(text)?.group(1) ?? '?';
            failures.add('[$currentLabel] ${message.split('\n').first}  ←  $source');
          };
          addTearDown(() => FlutterError.onError = previousOnError);

          await getIt<LocaleController>().changeLanguage(language);

          Future<void> settle([int ms = 1200]) async {
            for (var i = 0; i < ms ~/ 100; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          Future<void> visit(String label, Future<void> Function() action, {int ms = 1200}) async {
            currentLabel = label;
            await action();
            await settle(ms);
          }

          // ── Splash ──
          await tester.pumpWidget(const SinklyApp());
          AppRouter.router.go(AppRouter.kSplashView);
          await visit('splash', () async {}, ms: 1000);

          // ── Onboarding: all 15 steps ──
          await visit('onboarding', () async => AppRouter.router.go(AppRouter.kOnboardingView));
          final onboarding = tester.element(find.byType(OnboardingView)).read<OnboardingCubit>();
          for (final step in OnboardingStep.values) {
            if (onboarding.state.currentStep != step) {
              await visit('onboarding/${step.index + 1}-${step.name}', () async {
                onboarding.nextStep();
              }, ms: 1400);
            } else {
              currentLabel = 'onboarding/${step.index + 1}-${step.name}';
            }
            // Fill the step with the "largest" realistic answers too.
            switch (step) {
              case OnboardingStep.nameInput:
                await visit('onboarding/2-name(long)', () async => onboarding.updateName('Alexandria-Margaret'));
              case OnboardingStep.dishPileupDiagnosisQuiz:
                for (final id in ['full_day', 'several_days', 'disgust_anxiety']) {
                  await visit('onboarding/5-pileup($id)', () async => onboarding.selectDishPileupSeverity(id));
                }
              case OnboardingStep.dishwashingStruggleEmpathy:
                for (final option in OnboardingQuizOptionModel.dishwashingStruggleOptions.map((o) => o.id)) {
                  await visit('onboarding/6-struggle($option)', () async => onboarding.selectMainStruggle(option));
                }
              case OnboardingStep.distractingAppsSelection:
                await visit('onboarding/9-apps(all)', () async {
                  for (final id in BlockableAppModel.catalog.map((a) => a.id)) {
                    if (!onboarding.state.preferences.blockedAppIds.contains(id)) onboarding.toggleBlockedApp(id);
                  }
                });
              case OnboardingStep.personalCommitment:
                await visit('onboarding/12-commit(confirmed)', () async => onboarding.confirmCommitment(), ms: 2000);
              case OnboardingStep.paywall:
                await settle(1500);
              default:
                break;
            }
          }

          // ── Other routes ──
          for (final (label, path) in [
            ('auth', AppRouter.kAuthView),
            ('paywall', AppRouter.kPaywallView),
            ('home', AppRouter.kHomeView),
            ('plan', AppRouter.kLockScheduleView),
            ('progress', AppRouter.kProgressView),
            ('settings', AppRouter.kSettingsView),
            ('feedback', AppRouter.kFeedbackView),
          ]) {
            await visit(label, () async => AppRouter.router.go(path), ms: 1500);
            await _scrollThrough(tester, () => currentLabel = '$label(scrolled)');
            await settle(400);
          }

          // ── Sink unlock: intro → sprint ──
          await visit('unlock/intro', () async => AppRouter.router.go(AppRouter.kSinkUnlockView), ms: 1500);
          final unlock = tester.element(find.byType(SinkUnlockView)).read<SinkUnlockCubit>();
          await visit('unlock/sprint', () async => unlock.startSprint(), ms: 1500);

          // Tear down: leave a static tree so repeating animations/timers stop.
          currentLabel = 'teardown';
          await tester.pumpWidget(const SizedBox());
          await unlock.close();
          await settle(2500);

          expect(failures, isEmpty, reason: failures.toSet().join('\n'));
        });
      }
    }
  }
}

/// Scroll every scrollable on the current screen to its end so lazily-built
/// content (lists, cards at the bottom) is laid out too.
Future<void> _scrollThrough(WidgetTester tester, VoidCallback onScroll) async {
  onScroll();
  final scrollables = find.byType(Scrollable).hitTestable();
  for (var i = 0; i < scrollables.evaluate().length && i < 4; i++) {
    try {
      await tester.drag(scrollables.at(i), const Offset(0, -1500), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    } catch (_) {}
  }
}


// Responsive audit: renders EVERY screen of the app on a matrix of real-world
// phone sizes × text scales × languages (EN LTR / AR RTL) and fails on any
// layout error (RenderFlex overflow, unbounded constraints, …).
//
// Real fonts are loaded (Windows Arial / Flutter's bundled Roboto) instead of
// the square test glyphs, and the largest text scale is tested slightly above
// the app clamp (1.3) to cover width differences with Plus Jakarta Sans/Cairo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/models/onboarding_quiz_option_model.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/manager/onboarding_cubit.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/OnboardingView.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/hold_to_commit_button_widget.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/manager/sink_unlock_cubit.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/views/SinkUnlockView.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/views/widgets/sprint_duration_picker_widget.dart';
import 'package:sinkly/Features/Feature_03_Feedback/presentation/views/widgets/feedback_success_dialog_widget.dart';
import 'package:sinkly/Features/Feature_07_LockSchedule/presentation/manager/lock_schedule_cubit.dart';
import 'package:sinkly/Features/Feature_07_LockSchedule/presentation/views/LockScheduleView.dart';
import 'package:sinkly/Features/Feature_09_Settings/presentation/views/SettingsView.dart';
import 'package:sinkly/Features/Feature_09_Settings/presentation/views/widgets/settings_sheets_widget.dart';
import 'package:sinkly/core/models/blockable_app_model.dart';
import 'package:sinkly/core/models/sink_cleaning_session_model.dart';
import 'package:sinkly/core/models/weekly_lock_schedule_model.dart';
import 'package:sinkly/core/widgets/glass_bottom_sheet.dart';
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

  const windowsFonts = 'C:/Windows/Fonts';
  const regular = ['$windowsFonts/arial.ttf'];
  const bold = ['$windowsFonts/arialbd.ttf'];
  // google_fonts asks for "<Family>_<variant>" (e.g. PlusJakartaSans_700);
  // without network those names are unknown → register real metrics under them.
  for (final family in ['PlusJakartaSans', 'Cairo']) {
    await load(family, [...regular, ...bold]);
    for (final weight in [100, 200, 300, 400, 500, 600, 700, 800, 900]) {
      final variant = weight == 400 ? 'regular' : '$weight';
      await load('${family}_$variant', weight >= 600 ? bold : regular);
    }
  }
  await load('Roboto', [...regular, ...bold]);
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

          Future<void> settle([int ms = 1200]) async {
            for (var i = 0; i < ms ~/ 100; i++) {
              _trace('   pump $i');
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          SinkUnlockCubit? unlock;
          try {
            await getIt<LocaleController>().changeLanguage(language);

            Future<void> visit(String label, Future<void> Function() action, {int ms = 1200}) async {
              currentLabel = label;
              _trace('→ $label');
              await action();
              await settle(ms);
              await _screenshot(tester, '$language-${device.name}-x$scale', label);
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
                case OnboardingStep.screenTimePermission:
                  // Mock flow: first of the two Android switches granted.
                  await visit('onboarding/9-permission(step2)', () async {
                    onboarding.requestScreenTimePermission();
                  }, ms: 1400);
                case OnboardingStep.distractingAppsSelection:
                  await visit('onboarding/10-apps(all)', () async {
                    for (final id in BlockableAppModel.catalog.map((a) => a.id)) {
                      if (!onboarding.state.preferences.blockedAppIds.contains(id)) onboarding.toggleBlockedApp(id);
                    }
                  });
                  // Expand two categories + search, like a real user would.
                  for (final category in ['app_category_social', 'app_category_games']) {
                    final label = find.text(
                      AppLocalizations.of(tester.element(find.byType(OnboardingView))).translate(category),
                    );
                    if (label.evaluate().isNotEmpty) {
                      await tester.ensureVisible(label.first);
                      await tester.tap(label.first, warnIfMissed: false);
                    }
                  }
                  await visit('onboarding/10-apps(expanded)', () async {}, ms: 900);
                  await tester.enterText(find.byType(TextField).first, 'ta');
                  await visit('onboarding/10-apps(search)', () async {}, ms: 700);
                  await tester.enterText(find.byType(TextField).first, '');
                  FocusManager.instance.primaryFocus?.unfocus();
                  await settle(400);
                case OnboardingStep.personalCommitment:
                  // Mid-hold: heart grows while the finger is down.
                  final hold = await tester.startGesture(
                    tester.getCenter(find.byType(HoldToCommitButtonWidget, skipOffstage: false)),
                  );
                  await visit('onboarding/12-commit(holding)', () async {}, ms: 900);
                  await hold.up();
                  await settle(600);
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

            // ── Home while apps are LOCKED (manual test lock from the Plan tab) ──
            await visit('plan(test-lock)', () async {
              AppRouter.router.go(AppRouter.kLockScheduleView);
              for (var i = 0; i < 8; i++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
              // Not awaited: mock latency only advances while we pump.
              tester
                  .element(find.byType(LockScheduleView, skipOffstage: false))
                  .read<LockScheduleCubit>()
                  .triggerTestLockNow();
            }, ms: 2500);
            await visit('home(locked)', () async => AppRouter.router.go(AppRouter.kHomeView), ms: 1500);
            await _scrollThrough(tester, () => currentLabel = 'home(locked,scrolled)');

            // ── Sink unlock: intro → sprint ──
            await visit('unlock/intro', () async => AppRouter.router.go(AppRouter.kSinkUnlockView), ms: 1500);
            unlock = tester.element(find.byType(SinkUnlockView)).read<SinkUnlockCubit>();
            await visit('unlock/intro-sheet', () async {
              await tester.tap(find.byType(SprintDurationButtonWidget));
            }, ms: 1200);
            Navigator.of(tester.element(find.byType(SinkUnlockView))).pop();
            await settle(800);
            await visit('unlock/sprint', () async => unlock!.startSprint(), ms: 1500);
            await visit('unlock/sprint-sheet', () async {
              await tester.ensureVisible(find.byType(SprintDurationButtonWidget));
              await tester.tap(find.byType(SprintDurationButtonWidget));
            }, ms: 1200);
            Navigator.of(tester.element(find.byType(SinkUnlockView))).pop();
            await settle(800);
            await visit('unlock/verifying', () async {
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              unlock!.emit(unlock.state.copyWith(stage: SinkUnlockStage.verifying, photoPath: ''));
            }, ms: 1500);
            await visit('unlock/celebrating', () async {
              final now = DateTime.now();
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              unlock!.emit(
                unlock.state.copyWith(
                  stage: SinkUnlockStage.celebrating,
                  completedSession: SinkCleaningSessionModel(
                    id: 'audit',
                    startedAt: now.subtract(const Duration(minutes: 3, seconds: 42)),
                    completedAt: now,
                    triggeringMeal: MealType.values.last,
                  ),
                ),
              );
            }, ms: 2500);

            // ── Sheets & dialogs ──
            await visit('settings(again)', () async => AppRouter.router.go(AppRouter.kSettingsView), ms: 1200);
            BuildContext screen() => tester.element(find.byType(SettingsView));
            Future<void> openAndClose(String label, void Function() open, {bool isDialog = false}) async {
              await visit(label, () async {
                open(); // don't await: the sheet completes only when closed
              }, ms: 1200);
              // Sheets live on the tab's navigator, dialogs on the root one.
              _trace('   pop');
              Navigator.of(screen(), rootNavigator: isDialog).pop();
              _trace('   popped');
              await settle(800);
            }

            await openAndClose('sheet/language', () => showLanguagePickerSheet(screen(), currentCode: language));
            await openAndClose(
              'sheet/edit-name',
              () => showEditNameSheet(screen(), currentName: 'Alexandria-Margaret'),
            );
            await openAndClose('dialog/reset', () => showResetConfirmationDialog(screen()), isDialog: true);
            await openAndClose(
              'sheet/time-picker',
              () => showGlassTimePickerSheet(context: screen(), title: 'Dinner', initialMinutesOfDay: 19 * 60),
            );
            await openAndClose('dialog/feedback-success', () => showFeedbackSuccessDialog(screen()), isDialog: true);
          } catch (error, stack) {
            failures.add('[$currentLabel] EXCEPTION: $error\n${stack.toString().split('\n').take(8).join('\n')}');
          } finally {
            FlutterError.onError = previousOnError;
            // Leave a static tree so repeating animations/timers stop.
            await tester.pumpWidget(const SizedBox());
            await unlock?.close();
            await settle(8000); // let mock delays & auto-dismiss timers finish
          }

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

void _trace(String line) {
  final path = Platform.environment['AUDIT_TRACE'];
  if (path != null) {
    File(path).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }
}

/// Optional: `AUDIT_SHOTS=<dir>` saves a PNG of every visited screen for visual review.
Future<void> _screenshot(WidgetTester tester, String config, String label) async {
  final dir = Platform.environment['AUDIT_SHOTS'];
  if (dir == null) return;
  final renderView = tester.binding.renderViews.first;
  final layer = renderView.debugLayer! as OffsetLayer;
  // The root layer is in physical pixels; save at logical (1x) size.
  final physical = tester.view.physicalSize;
  await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & physical, pixelRatio: 1 / tester.view.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final name = '$config--${label.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}.png';
    Directory(dir).createSync(recursive: true);
    File('$dir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

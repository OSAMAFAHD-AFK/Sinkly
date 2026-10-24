// Captures the real app screens used inside the store screenshots
// (store/google_play/screenshots), at 3x on a 412x892 dp phone, with the real
// fonts and icons and a believable demo account (name, plan, a 2-week streak).
//
// Run from the project root:
//   flutter test tool/store_assets/capture_store_screens_test.dart
// First: python tool/store_assets/build_emoji_fonts.py (colour emoji).
// Optional: SINK_PHOTO=<png> is shown on the "checking your sink" screen (the one used
// is tool/store_assets/sink_photo.html screenshotted at 1080x1080 in Edge).
// Output: build/store_screens/*.png, then compose with tool/store_assets/render_store_images.py.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/manager/onboarding_cubit.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/OnboardingView.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/manager/sink_unlock_cubit.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/views/SinkUnlockView.dart';
import 'package:sinkly/core/models/sink_cleaning_session_model.dart';
import 'package:sinkly/core/models/sink_progress_stats_model.dart';
import 'package:sinkly/core/models/user_plan_model.dart';
import 'package:sinkly/core/models/weekly_lock_schedule_model.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/app_router.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';
import 'package:sinkly/core/utils/service_locator.dart';
import 'package:sinkly/main.dart';

const _outDir = 'build/store_screens';
const _logical = Size(412, 892);
const _dpr = 3.0;
const _assets = 'build/unit_test_assets';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File(file).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  // Icons: everything the app declares (Material, Cupertino, Font Awesome).
  final manifest = jsonDecode(File('$_assets/FontManifest.json').readAsStringSync()) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final fonts = (entry['fonts'] as List).cast<Map<String, dynamic>>();
    await load(entry['family'] as String, [for (final font in fonts) '$_assets/${font['asset']}']);
  }

  // The brand font under the names google_fonts asks for. The test engine has
  // no font fallback, so emoji need the merged fonts from build_emoji_fonts.py.
  final dir = Directory('build/store_fonts').existsSync() ? 'build/store_fonts' : 'assets/google_fonts';
  String file(int weight) => switch (weight) {
    <= 400 => '$dir/PlusJakartaSans-Regular.ttf',
    500 => '$dir/PlusJakartaSans-Medium.ttf',
    600 => '$dir/PlusJakartaSans-SemiBold.ttf',
    700 => '$dir/PlusJakartaSans-Bold.ttf',
    _ => '$dir/PlusJakartaSans-ExtraBold.ttf',
  };
  for (final weight in [100, 200, 300, 400, 500, 600, 700, 800, 900]) {
    await load('PlusJakartaSans_${weight == 400 ? 'regular' : '$weight'}', [file(weight)]);
  }
  await load('PlusJakartaSans', [file(400), file(700)]);
  await load('Roboto', [file(400), file(700)]);
}

/// The demo account: three meals a day; the latest one ended ~30 min ago.
(UserPlanModel, List<SinkCleaningSessionModel>, int) _demoAccount(DateTime now) {
  var lastMealEnd = (now.hour * 60 + now.minute - 25) ~/ 30 * 30;
  if (lastMealEnd < 12 * 60) lastMealEnd = 12 * 60;
  final meals = [
    const MealSlotModel(type: MealType.breakfast, minutesOfDay: 8 * 60 + 30),
    MealSlotModel(type: MealType.lunch, minutesOfDay: lastMealEnd <= 14 * 60 ? lastMealEnd : 13 * 60 + 30),
    MealSlotModel(type: MealType.dinner, minutesOfDay: lastMealEnd > 14 * 60 ? lastMealEnd : 20 * 60),
  ];
  final plan = UserPlanModel.initial().copyWith(
    userName: 'Emma',
    schedule: WeeklyLockScheduleModel(
      days: {for (final day in WeeklyLockScheduleModel.weekdays) day: DayMealPlanModel(isActive: true, meals: meals)},
    ),
    blockedAppIds: const ['tiktok', 'instagram', 'youtube', 'snapchat', 'facebook', 'reddit'],
    onboardingCompleted: true,
    screenTimePermissionGranted: true,
    lockingActiveSince: now.subtract(const Duration(days: 30)),
    sprintMinutes: 5,
  );

  // A 13-day streak up to yesterday; today's clean is added on camera.
  final sessions = <SinkCleaningSessionModel>[];
  final perDay = [2, 3, 2, 3, 3, 2, 3, 2, 3, 3, 2, 3, 2, 1, 2, 2, 1];
  for (var back = 1; back <= 13; back++) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: back));
    for (var i = 0; i < perDay[back % perDay.length]; i++) {
      final end = meals[i % meals.length].on(day).add(Duration(minutes: 6 + (back * 7 + i * 3) % 9));
      final minutes = 3 + (back + i) % 4;
      sessions.add(
        SinkCleaningSessionModel(
          id: 'demo-$back-$i',
          startedAt: end.subtract(Duration(minutes: minutes, seconds: (back * 13) % 50)),
          completedAt: end,
          triggeringMeal: meals[i % meals.length].type,
        ),
      );
    }
  }
  sessions.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  return (plan, sessions, lastMealEnd);
}

void main() {
  late UserPlanModel plan;
  late List<SinkCleaningSessionModel> sessions;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
    (plan, sessions, _) = _demoAccount(DateTime.now());
    // ignore: invalid_use_of_visible_for_testing_member — this tool runs as a test.
    SharedPreferences.setMockInitialValues({
      'sinkly.user_plan': jsonEncode(plan.toJson()),
      'sinkly.sink_sessions': jsonEncode([for (final s in sessions) s.toJson()]),
      'sinkly.mock_premium_active': true,
    });
    await setupServiceLocator();
    Directory(_outDir).createSync(recursive: true);
  });

  testWidgets('capture store screens', (tester) async {
    tester.view
      ..devicePixelRatio = _dpr
      ..physicalSize = _logical * _dpr
      ..padding = const FakeViewPadding(top: 40 * _dpr, bottom: 20 * _dpr);
    addTearDown(tester.view.reset);
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (!message.contains('oogle')) debugPrint('⚠ ${message.split('\n').first}');
    };

    Future<void> settle([int ms = 1500]) async {
      for (var i = 0; i < ms ~/ 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String name, [int ms = 1500]) async {
      await settle(ms);
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      await tester.runAsync(() async {
        final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    final storage = getIt<LocalStorageService>();
    await getIt<LocaleController>().changeLanguage('en');
    await tester.pumpWidget(const SinklyApp());

    // ── Locked: dinner just ended ──
    AppRouter.router.go(AppRouter.kHomeView);
    await shot('home_locked', 2500);
    AppRouter.router.go(AppRouter.kLockOverlayView);
    await shot('lock_overlay', 3500);

    AppRouter.router.go(AppRouter.kSinkUnlockView);
    await settle(400);
    final unlock = tester.element(find.byType(SinkUnlockView)).read<SinkUnlockCubit>();
    // A minute and a half into the sprint (the timer reads the real clock).
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 95)));
    await shot('sprint', 1500);
    final photo = Platform.environment['SINK_PHOTO'];
    if (photo != null) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      unlock.emit(unlock.state.copyWith(stage: SinkUnlockStage.verifying, photoPath: photo));
      // Image.file reads and decodes with real IO: alternate real waits and frames.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      }
      await shot('verifying', 1600);
    }
    final now = DateTime.now();
    final today = SinkCleaningSessionModel(
      id: 'demo-today',
      startedAt: now.subtract(const Duration(minutes: 4, seconds: 12)),
      completedAt: now,
      triggeringMeal: MealType.dinner,
    );
    storage.addSession(today); // not awaited: storage writes advance while pumping
    await settle(300);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    unlock.emit(
      unlock.state.copyWith(
        stage: SinkUnlockStage.celebrating,
        completedSession: today,
        statsAfterUnlock: SinkProgressStatsModel.fromSessions(storage.sessions, now: now),
      ),
    );
    await shot('celebrating', 2600);

    // ── Unlocked: today's sink is clean ──
    AppRouter.router.go(AppRouter.kHomeView);
    await shot('home', 2500);
    AppRouter.router.go(AppRouter.kLockScheduleView);
    await shot('plan', 2000);
    AppRouter.router.go(AppRouter.kProgressView);
    await shot('progress', 2500);
    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -520), warnIfMissed: false);
    await shot('progress_scrolled', 1200);

    // ── App picker (onboarding step) ──
    await getIt<OnboardingLocalDataSource>().saveDraft(plan: storage.plan, stepIndex: 0);
    AppRouter.router.go(AppRouter.kOnboardingView);
    await settle(800);
    final onboarding = tester.element(find.byType(OnboardingView)).read<OnboardingCubit>();
    while (onboarding.state.currentStep != OnboardingStep.distractingAppsSelection) {
      onboarding.nextStep();
      await settle(300);
    }
    await settle(1200);
    final social = find.text(
      AppLocalizations.of(tester.element(find.byType(OnboardingView))).translate('app_category_social'),
    );
    if (social.evaluate().isNotEmpty) await tester.tap(social.first, warnIfMissed: false);
    await shot('apps', 1500);

    // ── Heroine alone, for the feature graphic ──
    for (final (name, pose) in [
      ('heroine_wave', HeroinePose.waveJoy),
      ('heroine_cheer', HeroinePose.cheer),
      ('heroine_jump', HeroinePose.joyJump),
      ('heroine_wash', HeroinePose.washJoy),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: HeroineCharacterWidget(width: 260, pose: pose),
            ),
          ),
        ),
      );
      await settle(1500);
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(const SizedBox());
    await unlock.close();
    await settle(8000);
  });

  // App Store Connect "Review Information" screenshots of the paywall: the real
  // screens at the iPhone 15 Pro Max size (1290x2796), no Android chrome.
  // Run only these: flutter test tool/store_assets/capture_store_screens_test.dart --plain-name "capture paywall screens"
  testWidgets('capture paywall screens', (tester) async {
    const phone = Size(430, 932);
    tester.view
      ..devicePixelRatio = _dpr
      ..physicalSize = phone * _dpr
      ..padding = const FakeViewPadding(top: 59 * _dpr, bottom: 34 * _dpr);
    addTearDown(tester.view.reset);

    Future<void> settle(int ms) async {
      for (var i = 0; i < ms ~/ 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String name, int ms) async {
      await settle(ms);
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      await tester.runAsync(() async {
        final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await getIt<LocaleController>().changeLanguage('en');
    await getIt<OnboardingLocalDataSource>().saveDraft(
      plan: getIt<LocalStorageService>().plan,
      stepIndex: OnboardingStep.paywall.index,
    );
    await tester.pumpWidget(const SinklyApp());
    AppRouter.router.go(AppRouter.kOnboardingView);
    await shot('paywall', 12000);

    // "X" (appears after a short delay) → the exit offer.
    await tester.tap(find.byIcon(Icons.close_rounded).first, warnIfMissed: false);
    await shot('paywall_exit_offer', 3500);

    await tester.pumpWidget(const SizedBox());
    await settle(2000);
  });
}

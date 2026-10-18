import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_exit_offer_sheet_widget.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_heroine_hero_widget.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_step_widget.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/repos/app_blocking_repo_impl.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import 'package:sinkly/Features/Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';
import 'package:sinkly/core/widgets/confetti_burst_widget.dart';

Future<SubscriptionCubit> _cubit() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService(await SharedPreferences.getInstance());
  final blocking = AppBlockingRepoImpl(
    storage: storage,
    platform: MockAppBlockingPlatformDataSource(),
    permissions: MockDevicePermissionsDataSource(),
    localeController: LocaleController(storage),
  );
  return SubscriptionCubit(SubscriptionRepoImpl(MockSubscriptionRemoteDataSource(storage), blocking));
}

Future<void> _pumpPaywall(WidgetTester tester, SubscriptionCubit cubit, ValueChanged<bool> onFinished) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: PaywallStepWidget(userName: 'Sara', onFinished: onFinished),
        ),
      ),
    ),
  );
  // Plans load (mock latency 350 ms) + entrance animations.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 1));
}

/// Taps "X" (visible after the 3 s delay) → the exit-offer sheet.
Future<void> _openExitOffer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.tap(find.byIcon(Icons.close_rounded));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('paywall: annual pre-selected, purchase → celebration → onFinished(true)', (tester) async {
    final cubit = await _cubit();
    bool? finishedWith;
    await _pumpPaywall(tester, cubit, (value) => finishedWith = value);

    expect(cubit.state.selectedPlan?.id, 'annual');
    expect(find.byType(PaywallHeroineHeroWidget), findsOneWidget);

    await tester.tap(find.text('Start free trial for \$0'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cubit.state.status, SubscriptionStatus.purchasing);

    await tester.pump(const Duration(milliseconds: 1500)); // mock purchase completes
    await tester.pump(const Duration(milliseconds: 100));
    expect(cubit.state.isPremium, isTrue);
    expect(find.byType(ConfettiBurstWidget), findsOneWidget);
    expect(finishedWith, isNull, reason: 'celebration plays before leaving');

    await tester.pump(const Duration(milliseconds: 1900));
    expect(finishedWith, isTrue);

    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  testWidgets('strict paywall: X opens the offer, there is no way past it without buying', (tester) async {
    final cubit = await _cubit();
    bool? finishedWith;
    await _pumpPaywall(tester, cubit, (value) => finishedWith = value);

    await _openExitOffer(tester);
    expect(find.byType(PaywallExitOfferSheetWidget), findsOneWidget);
    expect(cubit.state.exitOffer?.localizedPrice, r'$29.99');
    expect(cubit.state.exitOffer?.discountPercent, 25);
    expect(cubit.state.exitOffer?.savingVsWeeklyPercent, 88);
    expect(find.text('SAVE 88%'), findsOneWidget, reason: 'the card ribbon compares with weekly');
    expect(find.text('No thanks'), findsNothing, reason: 'strict paywall: no decline button');

    // Dismissing the sheet (swipe down / barrier tap pops it with no result)
    // returns to the paywall.
    Navigator.of(tester.element(find.byType(PaywallExitOfferSheetWidget))).pop();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // slide-out + route removal
    }
    expect(find.byType(PaywallExitOfferSheetWidget), findsNothing);
    expect(finishedWith, isNull, reason: 'still on the paywall');
    expect(cubit.state.isPremium, isFalse);

    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  testWidgets('exit offer: claiming buys the discounted plan → celebration', (tester) async {
    final cubit = await _cubit();
    bool? finishedWith;
    await _pumpPaywall(tester, cubit, (value) => finishedWith = value);

    await _openExitOffer(tester);
    await tester.pump(PaywallExitOfferSheetWidget.sobLength); // gift appears
    await tester.tap(find.text('Claim my 25% off'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cubit.state.status, SubscriptionStatus.purchasing);

    await tester.pump(const Duration(milliseconds: 1500)); // mock purchase
    await tester.pump(const Duration(milliseconds: 1200)); // her joy, then the sheet closes
    await tester.pump(const Duration(milliseconds: 400));
    expect(cubit.state.isPremium, isTrue);
    expect(find.byType(ConfettiBurstWidget), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(finishedWith, isTrue);

    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}

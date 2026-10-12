import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_heroine_hero_widget.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_step_widget.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import 'package:sinkly/Features/Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';
import 'package:sinkly/core/widgets/confetti_burst_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('paywall: annual pre-selected, purchase → celebration → onFinished(true)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    final cubit = SubscriptionCubit(SubscriptionRepoImpl(MockSubscriptionRemoteDataSource(storage)));
    bool? finishedWith;

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
            body: PaywallStepWidget(userName: 'Sara', onFinished: (value) => finishedWith = value),
          ),
        ),
      ),
    );
    // Plans load (mock latency 350 ms) + entrance animations.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

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
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'Features/Feature_03_Feedback/data/repos/feedback_repo.dart';
import 'Features/Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import 'Features/Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'core/models/supported_language_model.dart';
import 'core/utils/app_constants.dart';
import 'core/utils/app_localizations.dart';
import 'core/utils/app_router.dart';
import 'core/utils/service_locator.dart';
import 'core/utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Future: await Adapty().activate(...);
  await setupServiceLocator();
  // Background, best effort: deliver ideas written offline. Touches Supabase only
  // when something is waiting, so installs that never use it never create a user.
  unawaited(getIt<FeedbackRepo>().flushPending());
  // Keeps the native app blocker in step with the plan from now on.
  final blocking = getIt<AppBlockingRepo>();
  unawaited(blocking.start());

  runApp(const SinklyApp());

  // A button on the native lock screen (or the iOS shield notification) while
  // Sinkly is running → the matching screen.
  blocking.lockOverlayRequests.listen((request) {
    final location = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (location == AppRouter.kSinkUnlockView) return;
    AppRouter.openNativeLockRequest(request);
  });
}

class SinklyApp extends StatelessWidget {
  const SinklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = getIt<LocaleController>();

    return MultiBlocProvider(
      providers: [
        // App-wide state shared by several features.
        BlocProvider(create: (_) => SubscriptionCubit(getIt())..initialize()),
      ],
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.router,
          locale: localeController.locale,
          supportedLocales: SupportedLanguageModel.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate, // RTL for Arabic
            GlobalCupertinoLocalizations.delegate,
          ],
          // Keep text scaling sane so the glass layouts never break.
          builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
        ),
      ),
    );
  }
}

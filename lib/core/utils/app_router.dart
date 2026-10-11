import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../Features/Feature_01_Auth/presentation/views/AuthView.dart';
import '../../Features/Feature_01_Auth/presentation/views/SplashView.dart';
import '../../Features/Feature_02_Onboarding/presentation/manager/onboarding_cubit.dart';
import '../../Features/Feature_02_Onboarding/presentation/views/OnboardingView.dart';
import '../../Features/Feature_03_Feedback/presentation/manager/feedback_cubit.dart';
import '../../Features/Feature_03_Feedback/presentation/views/FeedbackView.dart';
import '../../Features/Feature_04_Subscription/presentation/views/PaywallView.dart';
import '../../Features/Feature_05_Home/presentation/manager/home_cubit.dart';
import '../../Features/Feature_05_Home/presentation/views/HomeView.dart';
import '../../Features/Feature_06_SinkUnlock/presentation/manager/sink_unlock_cubit.dart';
import '../../Features/Feature_06_SinkUnlock/presentation/views/SinkUnlockView.dart';
import '../../Features/Feature_07_LockSchedule/presentation/manager/lock_schedule_cubit.dart';
import '../../Features/Feature_07_LockSchedule/presentation/views/LockScheduleView.dart';
import '../../Features/Feature_08_Progress/presentation/manager/progress_cubit.dart';
import '../../Features/Feature_08_Progress/presentation/views/ProgressView.dart';
import '../../Features/Feature_09_Settings/presentation/manager/settings_cubit.dart';
import '../../Features/Feature_09_Settings/presentation/views/SettingsView.dart';
import '../widgets/main_navigation_shell_widget.dart';
import 'service_locator.dart';

/// Declarative routes. Feature cubits are created per-route (and disposed
/// with it); app-wide cubits (Subscription, Auth) live above the router.
abstract final class AppRouter {
  static const String kSplashView = '/';
  static const String kOnboardingView = '/onboarding';
  static const String kAuthView = '/auth';
  static const String kPaywallView = '/paywall';
  static const String kSinkUnlockView = '/sink-unlock';
  static const String kFeedbackView = '/feedback';

  // Tabs (StatefulShellRoute branches)
  static const String kHomeView = '/home';
  static const String kLockScheduleView = '/plan';
  static const String kProgressView = '/progress';
  static const String kSettingsView = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: kSplashView,
    routes: [
      GoRoute(path: kSplashView, pageBuilder: (context, state) => _fade(state, const SplashView())),
      GoRoute(
        path: kOnboardingView,
        pageBuilder: (context, state) => _fade(
          state,
          BlocProvider(
            create: (_) => OnboardingCubit(repo: getIt(), localeController: getIt()),
            child: const OnboardingView(),
          ),
        ),
      ),
      GoRoute(path: kAuthView, pageBuilder: (context, state) => _fade(state, const AuthView())),
      GoRoute(path: kPaywallView, pageBuilder: (context, state) => _slideUp(state, const PaywallView())),
      GoRoute(
        path: kSinkUnlockView,
        pageBuilder: (context, state) =>
            _slideUp(state, BlocProvider(create: (_) => SinkUnlockCubit(getIt()), child: const SinkUnlockView())),
      ),
      GoRoute(
        path: kFeedbackView,
        builder: (context, state) => BlocProvider(create: (_) => FeedbackCubit(getIt()), child: const FeedbackView()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            _fade(state, MainNavigationShellWidget(navigationShell: navigationShell)),
        branches: [
          _tab(kHomeView, BlocProvider(create: (_) => HomeCubit(getIt()), child: const HomeView())),
          _tab(
            kLockScheduleView,
            BlocProvider(create: (_) => LockScheduleCubit(getIt()), child: const LockScheduleView()),
          ),
          _tab(kProgressView, BlocProvider(create: (_) => ProgressCubit(getIt()), child: const ProgressView())),
          _tab(kSettingsView, BlocProvider(create: (_) => SettingsCubit(getIt()), child: const SettingsView())),
        ],
      ),
    ],
  );

  static StatefulShellBranch _tab(String path, Widget child) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: child),
      ),
    ],
  );

  static CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    ),
  );

  /// iOS modal-like presentation for focused flows (unlock, paywall).
  static CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

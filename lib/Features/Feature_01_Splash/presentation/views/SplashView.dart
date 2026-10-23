import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_router.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../data/models/app_start_destination_model.dart';
import '../manager/splash_cubit.dart';
import 'widgets/splash_kitchen_scene_widget.dart';

/// Brand splash + session gate (onboarding vs. home).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Leave the full brand animation on screen before routing.
    context.read<SplashCubit>().start(SplashKitchenSceneWidget.totalDuration);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, AppStartDestination?>(
      listenWhen: (previous, current) => current != null,
      listener: (context, destination) {
        context.go(switch (destination!) {
          AppStartDestination.home => AppRouter.kHomeView,
          AppStartDestination.paywall => AppRouter.kSubscribeView,
          AppStartDestination.onboarding => AppRouter.kOnboardingView,
        });
        // Launched from a locked app: its lock overlay goes on top of Home.
        final lockRequest = context.read<SplashCubit>().pendingLockOverlay;
        if (lockRequest != null) AppRouter.openNativeLockRequest(lockRequest);
      },
      // Full-bleed illustrated scene: the sink sits on the bottom edge.
      child: const GlassScreenScaffold(animateBackground: true, useSafeArea: false, body: SplashKitchenSceneWidget()),
    );
  }
}

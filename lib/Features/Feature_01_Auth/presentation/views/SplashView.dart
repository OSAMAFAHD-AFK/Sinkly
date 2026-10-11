import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_router.dart';
import '../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../data/repos/auth_repo.dart';
import '../manager/auth_cubit.dart';
import 'widgets/splash_animated_logo_widget.dart';

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
    Future<void>.delayed(const Duration(milliseconds: 1900), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final destination = context.read<AuthCubit>().resolveStartDestination();
    context.go(destination == AppStartDestination.home ? AppRouter.kHomeView : AppRouter.kOnboardingView);
  }

  @override
  Widget build(BuildContext context) {
    return const GlassScreenScaffold(
      animateBackground: true,
      body: Stack(
        children: [
          Positioned.fill(child: FloatingSoapBubblesWidget(bubbleCount: 12, maxBubbleSize: 42)),
          Center(child: SplashAnimatedLogoWidget()),
        ],
      ),
    );
  }
}

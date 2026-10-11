import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';

/// Thin glass track with a glowing sky fill that eases forward per step.
class OnboardingProgressBarWidget extends StatelessWidget {
  const OnboardingProgressBarWidget({super.key, required this.progress});

  /// 0 … 1
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0, 1)),
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Container(
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: AppRadii.pillAll,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

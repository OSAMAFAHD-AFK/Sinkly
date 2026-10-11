import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_primary_button.dart';

/// Presents the thank-you popup with a springy entrance and confetti.
Future<void> showFeedbackSuccessDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.tr('close'),
    barrierColor: AppColors.ink.withValues(alpha: 0.2),
    transitionDuration: AppDurations.slow,
    pageBuilder: (_, _, _) => const FeedbackSuccessDialogWidget(),
    transitionBuilder: (context, animation, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: animation, child: child),
    ),
  );
}

class FeedbackSuccessDialogWidget extends StatelessWidget {
  const FeedbackSuccessDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ConfettiBurstWidget()),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: AppRadii.largeAll,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: AppRadii.largeAll,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.floating,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryButton,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.primaryGlow(),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                        ).animate().scaleXY(
                          begin: 0.4,
                          end: 1,
                          delay: 150.ms,
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.tr('feedback_success_title'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr('feedback_success_message'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CustomPrimaryButton(label: context.tr('done'), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

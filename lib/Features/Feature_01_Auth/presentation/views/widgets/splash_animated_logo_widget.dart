import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';

/// Splash brand moment: the drop badge pops in, a ripple expands from it,
/// then the wordmark and tagline glide up.
class SplashAnimatedLogoWidget extends StatelessWidget {
  const SplashAnimatedLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Water ripple rings.
              for (var i = 0; i < 2; i++)
                Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(), delay: (500 + i * 600).ms)
                    .scaleXY(begin: 0.8, end: 1.8, duration: 1600.ms, curve: Curves.easeOut)
                    .fadeOut(duration: 1600.ms),
              const SinklyLogoWidget(size: 56, showWordmark: false)
                  .animate()
                  .scaleXY(begin: 0.3, end: 1, duration: 700.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 250.ms),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sinkly',
          style: AppTextStyles.display.copyWith(fontSize: 40),
        ).animate(delay: 350.ms).fadeIn(duration: 450.ms).slideY(begin: 0.4, curve: Curves.easeOutCubic),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('splash_tagline'),
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ).animate(delay: 550.ms).fadeIn(duration: 450.ms).slideY(begin: 0.4, curve: Curves.easeOutCubic),
      ],
    );
  }
}

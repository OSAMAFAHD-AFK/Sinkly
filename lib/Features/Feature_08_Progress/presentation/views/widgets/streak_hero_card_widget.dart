import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Big flame + animated streak counter + best streak.
class StreakHeroCardWidget extends StatelessWidget {
  const StreakHeroCardWidget({super.key, required this.currentStreak, required this.bestStreak});

  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF2FFFFFF), Color(0xE6FFF4E0)],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.flame.withValues(alpha: 0.3), AppColors.flame.withValues(alpha: 0)],
              ),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 52))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.94, end: 1.06, duration: 900.ms, curve: Curves.easeInOut),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: currentStreak),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) =>
                      Text('$value', style: AppTextStyles.statNumber.copyWith(fontSize: 48)),
                ),
                Text(context.tr('progress_streak_label'), style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  currentStreak == 0
                      ? context.tr('progress_streak_start_hint')
                      : context.tr('progress_best_streak', {'days': '$bestStreak'}),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

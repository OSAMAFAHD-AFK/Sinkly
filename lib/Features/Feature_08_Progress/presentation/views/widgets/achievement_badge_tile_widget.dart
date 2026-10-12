import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../data/models/achievement_badge_model.dart';

/// Badge tile: glowing when unlocked, grayscale with a progress ring when not.
class AchievementBadgeTileWidget extends StatelessWidget {
  const AchievementBadgeTileWidget({super.key, required this.badge});

  final AchievementBadgeModel badge;

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final emoji = Text(badge.emoji, style: const TextStyle(fontSize: 28));
    return CustomCardContainer(
      borderRadius: AppRadii.mediumAll,
      shadows: badge.isUnlocked ? AppShadows.primaryGlow(strength: 0.35) : AppShadows.soft,
      fillColor: badge.isUnlocked ? AppColors.glassFillStrong : AppColors.glassFill,
      borderColor: badge.isUnlocked ? AppColors.primary.withValues(alpha: 0.6) : AppColors.glassBorder,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: badge.progress,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(badge.isUnlocked ? AppColors.success : AppColors.primary),
                  ),
                ),
                if (badge.isUnlocked) emoji else ColorFiltered(colorFilter: _grayscale, child: emoji),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Text(
              context.tr(badge.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                color: badge.isUnlocked ? AppColors.ink : AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

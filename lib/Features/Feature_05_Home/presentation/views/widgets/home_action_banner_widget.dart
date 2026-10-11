import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Tappable glass banner (emoji · title · subtitle · chevron). Used for the
/// feedback invite and the premium upsell on Home.
class HomeActionBannerWidget extends StatelessWidget {
  const HomeActionBannerWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Sky-tinted variant to draw more attention (premium upsell).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: title,
      child: CustomCardContainer(
        fillColor: highlighted ? AppColors.primarySoft.withValues(alpha: 0.9) : AppColors.glassFill,
        borderColor: highlighted ? AppColors.primary.withValues(alpha: 0.6) : AppColors.glassBorder,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.smallAll,
                boxShadow: AppShadows.soft,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyStrong),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

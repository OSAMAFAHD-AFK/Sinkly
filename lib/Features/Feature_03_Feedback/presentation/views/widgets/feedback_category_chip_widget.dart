import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';

/// Single-select glass chip (emoji + label). Selected = sky gradient + glow.
class FeedbackCategoryChipWidget extends StatelessWidget {
  const FeedbackCategoryChipWidget({
    super.key,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryButton : null,
          color: isSelected ? null : AppColors.glassFillStrong,
          borderRadius: AppRadii.pillAll,
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.5) : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

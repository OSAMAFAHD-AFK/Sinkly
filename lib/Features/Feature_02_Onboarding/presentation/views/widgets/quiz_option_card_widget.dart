import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Glass answer card for single-choice quiz steps (emoji + text + radio).
class QuizOptionCardWidget extends StatelessWidget {
  const QuizOptionCardWidget({
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
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardAll,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 26,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
                ]
              : const [],
        ),
        child: CustomCardContainer(
          fillColor: isSelected ? AppColors.primarySoft.withValues(alpha: 0.9) : AppColors.glassFill,
          borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
          borderWidth: isSelected ? 1.8 : 1.2,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md + 2),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.mediumAll,
                  boxShadow: AppShadows.soft,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTextStyles.bodyStrong)),
              const SizedBox(width: AppSpacing.xs),
              _SelectionRadio(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionRadio extends StatelessWidget {
  const _SelectionRadio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected ? AppGradients.primaryButton : null,
        color: isSelected ? null : Colors.white,
        border: Border.all(color: isSelected ? Colors.white : AppColors.divider, width: 2),
      ),
      child: AnimatedScale(
        scale: isSelected ? 1 : 0,
        duration: AppDurations.medium,
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
      ),
    );
  }
}

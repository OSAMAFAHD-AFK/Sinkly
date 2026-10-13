import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/adaptive_tile_grid_widget.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../data/models/user_feedback_model.dart';
import '../../manager/feedback_cubit.dart';

/// All four categories at a glance (2 × 2, one column on tiny phones or huge
/// text) — no horizontal scrolling.
class FeedbackCategoryGridWidget extends StatelessWidget {
  const FeedbackCategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select((FeedbackCubit cubit) => cubit.state.category);
    const categories = FeedbackCategory.values;
    return AdaptiveTileGridWidget(
      itemCount: categories.length,
      minTileWidth: 136,
      fixedExtent: 30,
      textExtent: 38,
      itemBuilder: (context, index) {
        final category = categories[index];
        return FeedbackCategoryTileWidget(
          emoji: category.emoji,
          accent: category.accent,
          label: context.tr(category.translationKey),
          isSelected: category == selected,
          onTap: () => context.read<FeedbackCubit>().selectCategory(category),
        );
      },
    );
  }
}

extension on FeedbackCategory {
  /// Soft tint behind each emoji so the four tiles are told apart at once.
  Color get accent => switch (this) {
    FeedbackCategory.newFeature => const Color(0xFFFFE9A8),
    FeedbackCategory.uiEnhancement => const Color(0xFFFFD6E4),
    FeedbackCategory.bugReport => const Color(0xFFCFF3E2),
    FeedbackCategory.appLockOptions => const Color(0xFFE2DCFF),
  };
}

/// Glass tile: tinted emoji badge + label. Selected = sky gradient, glow, a
/// check mark, and the emoji does a happy little wiggle.
class FeedbackCategoryTileWidget extends StatelessWidget {
  const FeedbackCategoryTileWidget({
    super.key,
    required this.emoji,
    required this.accent,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final Color accent;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget badgeEmoji = Text(emoji, style: const TextStyle(fontSize: 20));
    if (isSelected) {
      badgeEmoji = badgeEmoji
          .animate()
          .scaleXY(begin: 0.6, end: 1, duration: 520.ms, curve: Curves.elasticOut)
          .shake(hz: 5, rotation: 0.12, duration: 520.ms);
    }

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedPressableWidget(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.primaryButton : null,
            color: isSelected ? null : AppColors.glassFillStrong,
            borderRadius: AppRadii.mediumAll,
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.55) : AppShadows.soft,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.medium,
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white.withValues(alpha: 0.92) : accent,
                  boxShadow: isSelected ? AppShadows.soft : const [],
                ),
                child: badgeEmoji,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.onPrimary : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedScale(
                scale: isSelected ? 1 : 0,
                duration: AppDurations.medium,
                curve: Curves.easeOutBack,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

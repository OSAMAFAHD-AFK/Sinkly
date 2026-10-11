import 'package:flutter/material.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Selectable glass tile for a distracting app (onboarding screen 9 and the
/// Plan tab). Selected = sky outline + glow + lock badge on the icon.
class DistractingAppSelectionTileWidget extends StatelessWidget {
  const DistractingAppSelectionTileWidget({
    super.key,
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final BlockableAppModel app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: app.displayName,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          borderRadius: AppRadii.mediumAll,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: CustomCardContainer(
          borderRadius: AppRadii.mediumAll,
          shadows: AppShadows.soft,
          fillColor: isSelected ? AppColors.primarySoft.withValues(alpha: 0.92) : AppColors.glassFill,
          borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
          borderWidth: isSelected ? 1.8 : 1.2,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              BlockableAppIconWidget(app: app, size: 40, showLockBadge: isSelected),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  app.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.primaryInk : AppColors.divider,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

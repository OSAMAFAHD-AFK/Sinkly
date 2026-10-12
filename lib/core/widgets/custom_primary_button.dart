import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/style.dart';
import 'animated_pressable_widget.dart';

/// Sky-blue pill CTA with a glass highlight and a colored glow shadow.
class CustomPrimaryButton extends StatelessWidget {
  const CustomPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.showShimmer = false,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// A slow light sweep that draws the eye to key conversion CTAs.
  final bool showShimmer;
  final double height;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20, color: AppColors.onPrimary), const SizedBox(width: 10)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(trailingIcon, size: 20, color: AppColors.onPrimary),
        ],
      ],
    );

    if (isLoading) {
      content = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.onPrimary),
      );
    }

    Widget button = AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      // Min (not fixed) height: a 2-line label on large text grows the pill.
      constraints: BoxConstraints(minHeight: height),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillAll,
        gradient: _enabled ? AppGradients.primaryButton : null,
        color: _enabled ? null : AppColors.divider,
        boxShadow: _enabled ? AppShadows.primaryGlow() : const [],
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.pillAll,
        // Glass highlight on the upper half of the pill.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: _enabled ? 0.38 : 0.2),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(duration: AppDurations.fast, child: content),
    );

    if (showShimmer && _enabled) {
      button = button
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(delay: 1800.ms, duration: 1400.ms, color: Colors.white.withValues(alpha: 0.55));
    }

    return Opacity(
      opacity: _enabled || isLoading ? 1 : 0.7,
      child: AnimatedPressableWidget(onTap: _enabled ? onPressed : null, semanticLabel: label, child: button),
    );
  }
}

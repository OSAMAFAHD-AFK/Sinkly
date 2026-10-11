import 'package:flutter/material.dart';

import '../utils/style.dart';
import 'animated_pressable_widget.dart';

/// Frosted-glass pill used for secondary actions ("Maybe later", "Restore").
class CustomSecondaryButton extends StatelessWidget {
  const CustomSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.foregroundColor = AppColors.ink,
    this.isDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double height;
  final Color foregroundColor;

  /// Dark ink variant (used for "Continue with Apple").
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : foregroundColor;
    return AnimatedPressableWidget(
      onTap: onPressed,
      semanticLabel: label,
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadii.pillAll,
          color: isDark ? null : AppColors.glassFillStrong,
          gradient: isDark ? AppGradients.ink : null,
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white, width: 1.2),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(color: textColor, size: 20),
                child: icon!,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/app_localizations.dart';
import '../utils/style.dart';
import 'animated_pressable_widget.dart';
import 'custom_card_container.dart';

/// Round frosted-glass icon button (top-bar actions, back, close).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 46,
    this.iconColor = AppColors.ink,
    this.semanticLabel,
    this.badge = false,
  });

  /// RTL-aware back button.
  factory GlassIconButton.back({Key? key, required BuildContext context, VoidCallback? onPressed}) => GlassIconButton(
    key: key,
    icon: context.isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    semanticLabel: context.tr('back'),
  );

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color iconColor;
  final String? semanticLabel;

  /// Small sky dot (e.g. unread notification).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onPressed,
      pressedScale: 0.9,
      semanticLabel: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomCardContainer(
            width: size,
            height: size,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(size / 2),
            fillColor: AppColors.glassFillStrong,
            shadows: AppShadows.soft,
            child: Center(
              child: Icon(icon, size: size * 0.4, color: iconColor),
            ),
          ),
          if (badge)
            PositionedDirectional(
              top: 10,
              end: 11,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

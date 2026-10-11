import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';

/// Row inside a settings group: tinted icon bubble · title/subtitle · trailing.
class SettingsTileWidget extends StatelessWidget {
  const SettingsTileWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primaryInk,
    this.iconBackground = AppColors.primarySoft,
    this.titleColor = AppColors.ink,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBackground;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final chevron = Icon(
      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      color: AppColors.inkMuted,
    );
    return AnimatedPressableWidget(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBackground, borderRadius: AppRadii.smallAll),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyStrong.copyWith(color: titleColor, fontSize: 14.5)),
                  if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            trailing ?? (onTap != null ? chevron : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/blockable_app_model.dart';
import '../utils/style.dart';
import 'blockable_app_icon_widget.dart';

/// Icons of the locked apps, capped at [maxIcons] + a "+N" chip — selecting
/// a whole category can mean dozens of apps.
class AppIconsWrapWidget extends StatelessWidget {
  const AppIconsWrapWidget({
    super.key,
    required this.apps,
    this.size = 46,
    this.maxIcons = 8,
    this.showLockBadge = false,
    this.alignment = WrapAlignment.start,
    this.spacing = 10,
    this.iconBuilder,
  });

  final List<BlockableAppModel> apps;
  final double size;
  final int maxIcons;
  final bool showLockBadge;
  final WrapAlignment alignment;
  final double spacing;

  /// Wraps each icon (e.g. staggered entrance animation).
  final Widget Function(int index, Widget icon)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final visible = apps.take(apps.length > maxIcons ? maxIcons - 1 : maxIcons).toList();
    final hidden = apps.length - visible.length;
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final (index, app) in visible.indexed)
          iconBuilder?.call(index, BlockableAppIconWidget(app: app, size: size, showLockBadge: showLockBadge)) ??
              BlockableAppIconWidget(app: app, size: size, showLockBadge: showLockBadge),
        if (hidden > 0)
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(size * 0.3),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text('+$hidden', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryInk)),
              ),
            ),
          ),
      ],
    );
  }
}

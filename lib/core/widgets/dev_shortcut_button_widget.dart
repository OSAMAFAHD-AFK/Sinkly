import 'package:flutter/material.dart';

import '../utils/style.dart';
import 'animated_pressable_widget.dart';

/// TODO(dev): DEVELOPMENT ONLY. Amber "DEV" pill for temporary testing
/// shortcuts (bypass the lock overlay, skip onboarding…). Each use is gated
/// by an `AppConstants.showDev…` flag; delete them all before release.
class DevShortcutButtonWidget extends StatelessWidget {
  const DevShortcutButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.developer_mode_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  static const Color _amberInk = Color(0xFFB7791F);

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onPressed,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: AppRadii.pillAll,
          border: Border.all(color: AppColors.warning, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _amberInk),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: _amberInk, letterSpacing: 0, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

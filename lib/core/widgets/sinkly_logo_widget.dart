import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import '../utils/style.dart';

/// Sinkly wordmark: a sky water-drop badge + bold rounded wordmark.
class SinklyLogoWidget extends StatelessWidget {
  const SinklyLogoWidget({super.key, this.size = 30, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size * 1.25,
      height: size * 1.25,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(size * 0.42),
        boxShadow: AppShadows.primaryGlow(strength: 0.7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.water_drop_rounded, size: size * 0.72, color: Colors.white),
    );

    if (!showWordmark) return badge;

    return Directionality(
      // The brand wordmark always reads left-to-right.
      textDirection: TextDirection.ltr,
      // Large text settings / narrow phones: shrink the lockup, never clip it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            SizedBox(width: size * 0.35),
            Text(
              AppConstants.appName,
              style: AppTextStyles.display.copyWith(fontSize: size, letterSpacing: -size * 0.03),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import '../utils/style.dart';
import 'sinkly_logo_mark_painter.dart';

/// Sinkly brand lockup: the Sink-Lock mark + bold rounded wordmark.
class SinklyLogoWidget extends StatelessWidget {
  const SinklyLogoWidget({super.key, this.size = 30, this.showWordmark = true});

  /// Wordmark font size; the mark is drawn at `size * 1.35`.
  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size * 1.35,
      child: CustomPaint(painter: SinklyLogoMarkPainter()),
    );

    if (!showWordmark) return mark;

    return Directionality(
      // The brand wordmark always reads left-to-right.
      textDirection: TextDirection.ltr,
      // Large text settings / narrow phones: shrink the lockup, never clip it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Soft halo with slowly turning light rays — the "spotlight" behind the
/// heroine on emotional moments (lock overlay, unlock celebration).
/// [color] changes blend smoothly. Still when the OS asks for reduced motion.
class SunburstRaysWidget extends StatefulWidget {
  const SunburstRaysWidget({super.key, this.color = AppColors.primary, this.rayCount = 14});

  final Color color;
  final int rayCount;

  @override
  State<SunburstRaysWidget> createState() => _SunburstRaysWidgetState();
}

class _SunburstRaysWidgetState extends State<SunburstRaysWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 28));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: widget.color),
        duration: AppDurations.slow,
        builder: (context, color, _) => RepaintBoundary(
          child: CustomPaint(painter: _RaysPainter(_controller, color ?? widget.color, widget.rayCount)),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.rotation, this.tint, this.rayCount) : super(repaint: rotation);

  final Animation<double> rotation;
  final Color tint;
  final int rayCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.9), tint.withValues(alpha: 0.35), tint.withValues(alpha: 0)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62)),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation.value * math.pi * 2);
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [tint.withValues(alpha: 0.32), tint.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    final sweep = math.pi * 2 / rayCount;
    for (var i = 0; i < rayCount; i++) {
      final angle = i * sweep;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(angle - sweep * 0.18) * radius, math.sin(angle - sweep * 0.18) * radius)
          ..lineTo(math.cos(angle + sweep * 0.18) * radius, math.sin(angle + sweep * 0.18) * radius)
          ..close(),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.rayCount != rayCount;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Iridescent soap bubbles slowly rising — Sinkly's playful signature motif.
/// One painter, deterministic positions, isolated in a [RepaintBoundary].
/// Place it in the foreground (not beneath glass cards) to keep blurs static.
class FloatingSoapBubblesWidget extends StatefulWidget {
  const FloatingSoapBubblesWidget({super.key, this.bubbleCount = 9, this.maxBubbleSize = 34});

  final int bubbleCount;
  final double maxBubbleSize;

  @override
  State<FloatingSoapBubblesWidget> createState() => _FloatingSoapBubblesWidgetState();
}

class _FloatingSoapBubblesWidgetState extends State<FloatingSoapBubblesWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 14))
    ..repeat();

  late final List<_Bubble> _bubbles = List.generate(widget.bubbleCount, (index) {
    final random = math.Random(index * 7919);
    return _Bubble(
      x: random.nextDouble(),
      phase: random.nextDouble(),
      size: widget.maxBubbleSize * (0.35 + random.nextDouble() * 0.65),
      sway: 8 + random.nextDouble() * 18,
      speed: 0.6 + random.nextDouble() * 0.6,
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _BubblesPainter(_controller, _bubbles), child: const SizedBox.expand()),
      ),
    );
  }
}

class _Bubble {
  const _Bubble({required this.x, required this.phase, required this.size, required this.sway, required this.speed});
  final double x;
  final double phase;
  final double size;
  final double sway;
  final double speed;
}

class _BubblesPainter extends CustomPainter {
  _BubblesPainter(this.animation, this.bubbles) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Bubble> bubbles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final progress = (animation.value * bubble.speed + bubble.phase) % 1.0;
      final y = size.height + bubble.size - progress * (size.height + bubble.size * 2);
      final x = bubble.x * size.width + math.sin(progress * math.pi * 4 + bubble.phase * 6) * bubble.sway;
      final center = Offset(x, y);
      final radius = bubble.size / 2;
      // Fade in at the bottom, fade out near the top.
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0);

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              Colors.white.withValues(alpha: 0.05 * opacity),
              AppColors.primary.withValues(alpha: 0.12 * opacity),
              AppColors.meshLavender.withValues(alpha: 0.35 * opacity),
            ],
            stops: const [0.0, 0.75, 1.0],
          ).createShader(rect),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.9 * opacity),
      );
      canvas.drawCircle(
        center.translate(-radius * 0.35, -radius * 0.35),
        radius * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => false;
}

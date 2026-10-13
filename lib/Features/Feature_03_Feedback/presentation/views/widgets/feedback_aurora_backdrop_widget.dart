import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';

/// Living night-sky backdrop of the "Sinkly Lab" hero: three soft aurora
/// lights drift slowly across the card while tiny stars twinkle.
///
/// Every motion uses whole-number frequencies of one 18 s loop, so the loop
/// is seamless. Frozen on a still frame when the OS asks for reduced motion.
class FeedbackAuroraBackdropWidget extends StatefulWidget {
  const FeedbackAuroraBackdropWidget({super.key});

  @override
  State<FeedbackAuroraBackdropWidget> createState() => _FeedbackAuroraBackdropWidgetState();
}

class _FeedbackAuroraBackdropWidgetState extends State<FeedbackAuroraBackdropWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
    value: 0.2,
  );

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
      child: RepaintBoundary(child: CustomPaint(painter: _AuroraPainter(_controller))),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static final List<_Star> _stars = () {
    final random = math.Random(11);
    return List.generate(
      18,
      (_) => _Star(
        position: Offset(random.nextDouble(), random.nextDouble() * 0.75),
        radius: 0.6 + random.nextDouble() * 1.1,
        speed: 1 + random.nextInt(4),
        phase: random.nextDouble() * math.pi * 2,
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final a = animation.value * math.pi * 2;
    final w = size.width;
    final h = size.height;

    void light(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(rect),
      );
    }

    // Sky light (top-start), lavender (end), rose glow rising from below.
    light(
      Offset(w * (0.18 + 0.14 * math.sin(a)), h * (0.12 + 0.08 * math.cos(a * 2))),
      w * 0.62,
      AppColors.primary.withValues(alpha: 0.55),
    );
    light(
      Offset(w * (0.88 + 0.08 * math.sin(a * 2 + 1)), h * (0.42 + 0.12 * math.cos(a + 0.6))),
      w * 0.52,
      const Color(0xFFB9A8FF).withValues(alpha: 0.42),
    );
    light(
      Offset(w * (0.5 + 0.22 * math.sin(a + 2.2)), h * (1.02 + 0.05 * math.sin(a * 3))),
      w * 0.5,
      const Color(0xFFFF9BB3).withValues(alpha: 0.26),
    );

    for (final star in _stars) {
      final twinkle = 0.5 + 0.5 * math.sin(a * star.speed + star.phase);
      canvas.drawCircle(
        Offset(star.position.dx * w, star.position.dy * h),
        star.radius * (0.8 + twinkle * 0.4),
        Paint()..color = Colors.white.withValues(alpha: 0.15 + twinkle * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.animation != animation;
}

class _Star {
  const _Star({required this.position, required this.radius, required this.speed, required this.phase});

  final Offset position;
  final double radius;
  final int speed;
  final double phase;
}

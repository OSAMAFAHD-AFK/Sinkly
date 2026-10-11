import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Lightweight one-shot confetti + sparkle burst (no packages, one painter).
/// Plays automatically when built; wrap in a keyed widget to replay.
class ConfettiBurstWidget extends StatefulWidget {
  const ConfettiBurstWidget({super.key, this.particleCount = 60, this.duration = const Duration(milliseconds: 2600)});

  final int particleCount;
  final Duration duration;

  @override
  State<ConfettiBurstWidget> createState() => _ConfettiBurstWidgetState();
}

class _ConfettiBurstWidgetState extends State<ConfettiBurstWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..forward();

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.primaryDeep,
    Color(0xFFFFC36B),
    AppColors.success,
    Color(0xFFB9A7FF),
    Color(0xFFFF9BB3),
  ];

  late final List<_Particle> _particles = List.generate(widget.particleCount, (index) {
    final random = math.Random(index * 31 + 7);
    final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.3;
    final speed = 0.55 + random.nextDouble() * 0.6;
    return _Particle(
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      color: _palette[index % _palette.length],
      size: 5 + random.nextDouble() * 7,
      spin: (random.nextDouble() - 0.5) * 12,
      isCircle: random.nextBool(),
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
        child: CustomPaint(painter: _ConfettiPainter(_controller, _particles), child: const SizedBox.expand()),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.isCircle,
  });
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.particles) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(animation.value);
    if (animation.value >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.42);
    final spread = size.shortestSide * 0.9;
    final gravity = size.height * 0.55;
    final fade = 1 - Curves.easeIn.transform(animation.value);

    for (final particle in particles) {
      final position =
          origin +
          Offset(
            particle.velocity.dx * spread * t,
            particle.velocity.dy * spread * t + gravity * animation.value * animation.value,
          );
      final paint = Paint()..color = particle.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.spin * animation.value);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.5),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}

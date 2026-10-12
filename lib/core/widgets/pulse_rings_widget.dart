import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Concentric rings that expand and fade behind [child] — a calm "heartbeat"
/// used for commitment, reminders and permission moments.
class PulseRingsWidget extends StatefulWidget {
  const PulseRingsWidget({
    super.key,
    required this.child,
    this.size = 220,
    this.color = AppColors.primary,
    this.ringCount = 3,
    this.duration = const Duration(milliseconds: 2800),
  });

  final Widget child;
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;

  @override
  State<PulseRingsWidget> createState() => _PulseRingsWidgetState();
}

class _PulseRingsWidgetState extends State<PulseRingsWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _RingsPainter(_controller, widget.color, widget.ringCount),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.animation, this.color, this.ringCount) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final int ringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    for (var i = 0; i < ringCount; i++) {
      final progress = (animation.value + i / ringCount) % 1.0;
      final eased = Curves.easeOut.transform(progress);
      final radius = maxRadius * (0.35 + 0.65 * eased);
      final alpha = (1 - progress) * 0.5;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - progress) + 0.5
          ..color = color.withValues(alpha: alpha),
      );
      canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: alpha * 0.12));
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

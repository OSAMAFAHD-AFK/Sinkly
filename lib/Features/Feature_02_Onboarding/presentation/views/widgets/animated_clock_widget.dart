import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';

/// Glass clock with a sweeping minute hand. [secondsPerTurn] controls the
/// urgency: fast on the time-loss screen, calm on the schedule screen.
/// [showLockBadge] adds a bouncing lock — "the clock triggers the lock".
class AnimatedClockWidget extends StatefulWidget {
  const AnimatedClockWidget({
    super.key,
    this.size = 110,
    this.secondsPerTurn = 3,
    this.showLockBadge = false,
    this.accent = AppColors.primary,
  });

  final double size;
  final double secondsPerTurn;
  final bool showLockBadge;
  final Color accent;

  @override
  State<AnimatedClockWidget> createState() => _AnimatedClockWidgetState();
}

class _AnimatedClockWidgetState extends State<AnimatedClockWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.secondsPerTurn * 1000).round()),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size * 1.25,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.45),
                  blurRadius: 34,
                  spreadRadius: -6,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(size: Size.square(widget.size), painter: _ClockPainter(_controller, widget.accent)),
          ),
          if (widget.showLockBadge)
            PositionedDirectional(
              end: 0,
              bottom: 2,
              child:
                  Container(
                        width: widget.size * 0.36,
                        height: widget.size * 0.36,
                        decoration: BoxDecoration(
                          gradient: AppGradients.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Icon(Icons.lock_rounded, color: Colors.white, size: widget.size * 0.18),
                      )
                      .animate(onPlay: (c) => c.repeat(), delay: 700.ms)
                      .scaleXY(begin: 1, end: 1.18, duration: 220.ms, curve: Curves.easeOut)
                      .then()
                      .scaleXY(begin: 1.18, end: 1, duration: 360.ms, curve: Curves.elasticOut)
                      .then(delay: 1800.ms),
            ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.animation, this.accent) : super(repaint: animation);

  final Animation<double> animation;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final t = animation.value;

    // Ticks.
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final long = i % 3 == 0;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * (radius - (long ? 15 : 11));
      final to = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 7);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = long ? 3 : 1.8
          ..strokeCap = StrokeCap.round
          ..color = long ? AppColors.ink : AppColors.inkMuted,
      );
    }

    // Time swept so far: a soft pie behind the minute hand.
    final sweep = t * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 16),
      -math.pi / 2,
      sweep,
      true,
      Paint()..color = accent.withValues(alpha: 0.2),
    );

    // Hands.
    final minuteAngle = sweep - math.pi / 2;
    final hourAngle = sweep / 12 - math.pi / 2 + 0.9;
    canvas
      ..drawLine(
        center,
        center + Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * 0.42),
        Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.ink,
      )
      ..drawLine(
        center,
        center + Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * 0.66),
        Paint()
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primaryInk,
      )
      ..drawCircle(center, 5.5, Paint()..color = AppColors.primaryInk)
      ..drawCircle(center, 2.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => false;
}

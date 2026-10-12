import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';

/// Screen 7 hero: a glass hourglass whose sand really drains — the top bulb
/// empties, a grain stream falls, a mound grows — then it flips with a
/// springy turn and starts again. Time slipping away, made visible.
/// [urgent] speeds it up and warms the sand color.
class HourglassSandWidget extends StatefulWidget {
  const HourglassSandWidget({super.key, this.height = 130, this.urgent = false});

  final double height;
  final bool urgent;

  @override
  State<HourglassSandWidget> createState() => _HourglassSandWidgetState();
}

class _HourglassSandWidgetState extends State<HourglassSandWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: _duration)..repeat();

  Duration get _duration => Duration(milliseconds: widget.urgent ? 2600 : 4400);

  @override
  void didUpdateWidget(covariant HourglassSandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urgent != widget.urgent) {
      _controller
        ..duration = _duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 0.75;
    return ExcludeSemantics(
      child: SizedBox(
        width: width * 1.6,
        height: widget.height * 1.15,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: width * 1.5,
              height: width * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (widget.urgent ? const Color(0xFFFFC7B3) : AppColors.primary).withValues(alpha: 0.45),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: Size(width, widget.height),
                painter: _HourglassPainter(_controller, urgent: widget.urgent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter(this.animation, {required this.urgent}) : super(repaint: animation);

  final Animation<double> animation;
  final bool urgent;

  // Design space: 120 × 160.
  static const double _w = 120;
  static const double _h = 160;
  static const double _flowEnd = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);
    final phase = animation.value;
    final flowing = phase < _flowEnd;
    final level = flowing ? Curves.easeInOutSine.transform(phase / _flowEnd) : 1.0;

    if (!flowing) {
      final flip = Curves.easeInOutBack.transform((phase - _flowEnd) / (1 - _flowEnd));
      canvas.translate(_w / 2, _h / 2);
      canvas.rotate(flip * math.pi);
      canvas.translate(-_w / 2, -_h / 2);
    }

    final bulbs = _bulbPath();
    // Glass body.
    canvas.drawPath(bulbs, Paint()..color = Colors.white.withValues(alpha: 0.75));

    final sandColors = urgent
        ? const [Color(0xFFFFC36B), Color(0xFFFF8A5B)]
        : const [Color(0xFFFFD98A), Color(0xFFFFB25B)];
    final sand = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: sandColors,
      ).createShader(const Rect.fromLTWH(0, 0, _w, _h));

    canvas.save();
    canvas.clipPath(bulbs);
    // Top sand: surface sinks toward the neck, with a little funnel dip.
    final topSurface = 22 + level * 56;
    if (level < 0.995) {
      canvas.drawPath(
        Path()
          ..moveTo(0, topSurface)
          ..lineTo(_w / 2 - 10, topSurface)
          ..lineTo(_w / 2, topSurface + 6 + level * 4)
          ..lineTo(_w / 2 + 10, topSurface)
          ..lineTo(_w, topSurface)
          ..lineTo(_w, 80)
          ..lineTo(0, 80)
          ..close(),
        sand,
      );
    }
    // Bottom mound grows.
    final mound = 6 + level * 46;
    canvas.drawPath(
      Path()
        ..moveTo(0, _h - 12)
        ..lineTo(0, _h - 12 - mound * 0.55)
        ..quadraticBezierTo(_w / 2, _h - 12 - mound * 1.25, _w, _h - 12 - mound * 0.55)
        ..lineTo(_w, _h - 12)
        ..close(),
      sand,
    );
    canvas.restore();

    // Falling stream + grains.
    if (flowing && level < 0.98) {
      final moundTop = _h - 12 - mound * 0.95;
      canvas.drawLine(
        const Offset(_w / 2, 80),
        Offset(_w / 2, moundTop),
        Paint()
          ..strokeWidth = 2.2
          ..color = sandColors.last,
      );
      for (var i = 0; i < 6; i++) {
        final p = (phase * 30 + i / 6) % 1.0;
        final y = 82 + p * (moundTop - 82);
        canvas.drawCircle(Offset(_w / 2 + math.sin(i * 2.3) * 1.6, y), 1.6, Paint()..color = sandColors.first);
      }
    }

    // Glass outline + highlights.
    canvas
      ..drawPath(
        bulbs,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = AppColors.primary,
      )
      ..drawPath(
        Path()
          ..moveTo(26, 24)
          ..quadraticBezierTo(24, 50, 44, 66),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.9),
      );

    // Caps.
    final cap = Paint()..color = AppColors.ink;
    canvas
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 2, 108, 12), const Radius.circular(6)), cap)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, _h - 14, 108, 12), const Radius.circular(6)), cap)
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(12, 5, 40, 3), const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    canvas.restore();
  }

  Path _bulbPath() => Path()
    ..moveTo(16, 14)
    ..lineTo(104, 14)
    ..cubicTo(104, 52, 70, 64, 64, 80)
    ..cubicTo(70, 96, 104, 108, 104, _h - 14)
    ..lineTo(16, _h - 14)
    ..cubicTo(16, 108, 50, 96, 56, 80)
    ..cubicTo(50, 64, 16, 52, 16, 14)
    ..close();

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) => oldDelegate.urgent != urgent;
}

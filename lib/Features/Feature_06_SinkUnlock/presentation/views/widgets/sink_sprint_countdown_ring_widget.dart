import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';

/// Glass countdown ring whose inside slowly fills with animated sky "water"
/// as the 4-minute sprint progresses. One painter, isolated repaints.
class SinkSprintCountdownRingWidget extends StatefulWidget {
  const SinkSprintCountdownRingWidget({
    super.key,
    required this.progress,
    required this.remainingSeconds,
    required this.caption,
    this.size = 250,
  });

  /// 0 → 1
  final double progress;
  final int remainingSeconds;
  final String caption;
  final double size;

  @override
  State<SinkSprintCountdownRingWidget> createState() => _SinkSprintCountdownRingWidgetState();
}

class _SinkSprintCountdownRingWidgetState extends State<SinkSprintCountdownRingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 60, spreadRadius: -10),
              ],
            ),
          ),
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, progress, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RingWithWaterPainter(wave: _waveController, progress: progress),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppFunctions.formatCountdown(widget.remainingSeconds),
                style: AppTextStyles.statNumber.copyWith(
                  fontSize: 52,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.caption,
                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingWithWaterPainter extends CustomPainter {
  _RingWithWaterPainter({required this.wave, required this.progress}) : super(repaint: wave);

  final Animation<double> wave;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2;
    const stroke = 14.0;
    final ringRadius = outerRadius - stroke;
    final innerRadius = ringRadius - stroke / 2 - 8;

    // Glass disc
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F9FE)],
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius)),
    );

    // Water fill rising with progress, with a moving sine wave on top.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)));
    final waterTop = center.dy + innerRadius - (innerRadius * 2) * (0.08 + progress * 0.62);
    final phase = wave.value * 2 * math.pi;
    for (final layer in const [(0.35, 1.0, 0.0), (0.55, 0.7, math.pi / 1.5)]) {
      final path = Path()..moveTo(center.dx - innerRadius, size.height);
      for (var x = -innerRadius; x <= innerRadius; x += 4) {
        final y = waterTop + math.sin((x / innerRadius) * 2 * math.pi + phase * layer.$2 + layer.$3) * 6;
        path.lineTo(center.dx + x, y);
      }
      path
        ..lineTo(center.dx + innerRadius, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.primary.withValues(alpha: layer.$1));
    }
    canvas.restore();

    // Track
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.85),
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: ringRadius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [Color(0xFFA6DCF5), AppColors.primary, AppColors.primaryDeep],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingWithWaterPainter oldDelegate) => oldDelegate.progress != progress;
}

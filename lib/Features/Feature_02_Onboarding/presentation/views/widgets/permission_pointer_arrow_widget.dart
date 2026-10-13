import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';

/// Hand-drawn arrow that swoops up into the permission frame and points at
/// the system popup's "allow" button. Apple puts that button on the START
/// side (left in English, right in Arabic), so the arrow mirrors with RTL.
/// Draws itself in, then gently bobs; [label] sits beside its tail.
class PermissionPointerArrowWidget extends StatelessWidget {
  const PermissionPointerArrowWidget({super.key, required this.label, this.height = 86, this.tipFraction = 0.27});

  final String label;
  final double height;

  /// Horizontal tip position, from the start edge (0…1).
  final double tipFraction;

  static const double _tailFraction = 0.46;

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Animate(
              onPlay: (c) => c.repeat(reverse: true),
              effects: [MoveEffect(begin: Offset.zero, end: const Offset(0, -6), duration: 900.ms, curve: Curves.easeInOut, delay: 900.ms)],
              child: Animate(
                effects: [
                  CustomEffect(
                    duration: 900.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => CustomPaint(
                      painter: _ArrowPainter(
                        progress: value,
                        mirror: isRtl,
                        tipFraction: tipFraction,
                        tailFraction: _tailFraction,
                      ),
                    ),
                  ),
                ],
                child: const SizedBox.expand(),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerEnd,
              widthFactor: 1 - _tailFraction - 0.04,
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glassFillStrong,
                    borderRadius: AppRadii.pillAll,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryInk),
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 400.ms).slideX(begin: context.isRtl ? 0.15 : -0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.progress, required this.mirror, required this.tipFraction, required this.tailFraction});

  final double progress;
  final bool mirror;
  final double tipFraction;
  final double tailFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    double x(double fraction) => (mirror ? 1 - fraction : fraction) * size.width;

    final tail = Offset(x(tailFraction), size.height - 6);
    final tip = Offset(x(tipFraction), 4);
    final c1 = Offset(x(tailFraction + 0.05), size.height * 0.35);
    final c2 = Offset(tip.dx, tip.dy + size.height * 0.5);
    final path = Path()
      ..moveTo(tail.dx, tail.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [AppColors.primary.withValues(alpha: 0.35), AppColors.primaryInk],
      ).createShader(Offset.zero & size);

    final PathMetric metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(drawn, paint);

    // Arrow head appears once the line reaches the tip.
    if (progress > 0.92) {
      final tangent = metric.getTangentForOffset(metric.length)!;
      final direction = tangent.vector / tangent.vector.distance;
      final headLength = 14.0 * ((progress - 0.92) / 0.08).clamp(0.0, 1.0);
      for (final angle in [math.pi * 0.82, -math.pi * 0.82]) {
        final rotated = Offset(
          direction.dx * math.cos(angle) - direction.dy * math.sin(angle),
          direction.dx * math.sin(angle) + direction.dy * math.cos(angle),
        );
        canvas.drawLine(tip, tip + rotated * headLength, paint..shader = null..color = AppColors.primaryInk);
      }
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mirror != mirror || oldDelegate.tipFraction != tipFraction;
}

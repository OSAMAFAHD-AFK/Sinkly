import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../data/models/achievement_badge_model.dart';

/// Badge tile: glowing when unlocked, grayscale with a progress ring when not.
class AchievementBadgeTileWidget extends StatelessWidget {
  const AchievementBadgeTileWidget({super.key, required this.badge});

  final AchievementBadgeModel badge;

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final emoji = Text(badge.emoji, style: const TextStyle(fontSize: 28));
    return CustomCardContainer(
      borderRadius: AppRadii.mediumAll,
      shadows: badge.isUnlocked ? AppShadows.primaryGlow(strength: 0.35) : AppShadows.soft,
      fillColor: badge.isUnlocked ? AppColors.glassFillStrong : AppColors.glassFill,
      borderColor: badge.isUnlocked ? AppColors.primary.withValues(alpha: 0.6) : AppColors.glassBorder,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fills from 0 to the real value when the tab opens.
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: badge.progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: value,
                        color: badge.isUnlocked ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (badge.isUnlocked) emoji else ColorFiltered(colorFilter: _grayscale, child: emoji),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Text(
              context.tr(badge.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                color: badge.isUnlocked ? AppColors.ink : AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Exact progress ring, clockwise from 12 o'clock.
///
/// Replaces Material's `CircularProgressIndicator`, whose current design adds
/// rounded caps and a track gap on top of the sweep, so 5 / 10 visibly read
/// past half. Here the round caps are drawn INSIDE the sweep: the colored
/// arc, caps included, covers exactly [progress] of the circle.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const double _strokeWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    canvas.drawCircle(rect.center, radius, paint..color = AppColors.divider);

    final fraction = progress.clamp(0.0, 1.0);
    if (fraction <= 0) return;
    paint
      ..color = color
      ..strokeCap = fraction >= 1 ? StrokeCap.butt : StrokeCap.round;
    if (fraction >= 1) {
      canvas.drawCircle(rect.center, radius, paint);
      return;
    }
    // Each round cap pokes out by half the stroke; pull both ends in by that
    // angle so the visible length matches the value.
    final capAngle = (_strokeWidth / 2) / radius;
    final sweep = math.max(0.0, fraction * 2 * math.pi - 2 * capAngle);
    canvas.drawArc(rect, -math.pi / 2 + capAngle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

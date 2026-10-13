import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// "We're building it…" moment (steps 7 & 13): a glass orb that fills with
/// waving water as the percentage climbs, and task rows that light up one by
/// one (a live progress sweep → a bouncing check). Builds anticipation
/// before a reveal.
class AnalysisProgressChecklistWidget extends StatefulWidget {
  const AnalysisProgressChecklistWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onCompleted,
    this.emojis,
    this.duration = const Duration(milliseconds: 2600),
  });

  final String title;
  final List<String> items;

  /// Optional icon per item (defaults to ✨).
  final List<String>? emojis;
  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<AnalysisProgressChecklistWidget> createState() => _AnalysisProgressChecklistWidgetState();
}

class _AnalysisProgressChecklistWidgetState extends State<AnalysisProgressChecklistWidget>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    })
    ..forward();

  /// Endless clock for the waves & bubbles.
  late final AnimationController _waves = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _progress.dispose();
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return CustomCardContainer(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: AnimatedBuilder(
        animation: Listenable.merge([_progress, _waves]),
        builder: (context, _) {
          final value = Curves.easeInOutCubic.transform(_progress.value);
          return Column(
            children: [
              SizedBox.square(
                dimension: 150,
                child: CustomPaint(
                  painter: _WaterOrbPainter(level: value, phase: _waves.value),
                  child: Center(child: _Percent(value: value)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(widget.title, style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < count; i++)
                _TaskRow(
                  emoji: widget.emojis != null && i < widget.emojis!.length ? widget.emojis![i] : '✨',
                  label: widget.items[i],
                  // Each task owns an equal slice of the progress.
                  progress: ((value * (count + 0.4)) - i).clamp(0.0, 1.0),
                  shimmer: _waves.value,
                ),
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic);
  }
}

class _Percent extends StatelessWidget {
  const _Percent({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    // Turns white once the water rises behind it.
    final color = Color.lerp(AppColors.ink, Colors.white, ((value - 0.42) / 0.12).clamp(0.0, 1.0))!;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('${(value * 100).round()}', style: AppTextStyles.statNumber.copyWith(fontSize: 38, color: color)),
          Text('%', style: AppTextStyles.titleSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Glass orb whose inside fills with two layered sine waves + rising bubbles.
class _WaterOrbPainter extends CustomPainter {
  _WaterOrbPainter({required this.level, required this.phase});

  final double level;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final orb = Rect.fromCircle(center: center, radius: radius);

    // Halo + glass body.
    canvas
      ..drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.18 + 0.12 * level)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawCircle(center, radius, Paint()..color = AppColors.primarySoft);

    canvas.save();
    canvas.clipPath(Path()..addOval(orb));
    final surface = orb.bottom - orb.height * (0.04 + 0.92 * level);
    final angle = phase * 2 * math.pi;

    Path wave(double amplitude, double shift) {
      final path = Path()..moveTo(orb.left, orb.bottom);
      for (var x = orb.left; x <= orb.right; x += 4) {
        final y = surface + math.sin((x - orb.left) / orb.width * 2 * math.pi + angle + shift) * amplitude;
        path.lineTo(x, y);
      }
      return path
        ..lineTo(orb.right, orb.bottom)
        ..close();
    }

    canvas
      ..drawPath(wave(6, math.pi), Paint()..color = const Color(0xFF89CFF0).withValues(alpha: 0.55))
      ..drawPath(
        wave(5, 0),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8ED4F7), Color(0xFF3F97DA)],
          ).createShader(orb),
      );

    // Bubbles rising inside the water.
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 5; i++) {
      final t = (phase + i / 5) % 1;
      final x = orb.left + orb.width * (0.2 + 0.15 * i) + math.sin(t * 2 * math.pi + i) * 4;
      final y = orb.bottom - (orb.bottom - surface) * t;
      if (y > surface + 4) canvas.drawCircle(Offset(x, y), 2 + (i % 3).toDouble(), bubble);
    }
    canvas.restore();

    // Glass rim + highlight.
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white,
      )
      ..drawArc(
        orb.deflate(9),
        math.pi * 1.1,
        math.pi * 0.35,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.6),
      );
  }

  @override
  bool shouldRepaint(covariant _WaterOrbPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.phase != phase;
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.emoji, required this.label, required this.progress, required this.shimmer});

  final String emoji;
  final String label;

  /// 0 = waiting · (0,1) = working · 1 = done.
  final double progress;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    final working = progress > 0 && !done;
    return AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: done
            ? AppColors.successSoft.withValues(alpha: 0.75)
            : working
            ? AppColors.primarySoft.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: AppDurations.medium,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 14,
                    color: progress > 0 ? AppColors.ink : AppColors.inkMuted,
                  ),
                  child: Text(label),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedSwitcher(
                duration: AppDurations.medium,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  child: child,
                ),
                child: done
                    ? const Icon(Icons.check_circle_rounded, key: ValueKey('done'), color: AppColors.success, size: 24)
                    : SizedBox.square(
                        key: const ValueKey('wait'),
                        dimension: 24,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: working
                              ? const CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary)
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.divider, width: 2),
                                  ),
                                ),
                        ),
                      ),
              ),
            ],
          ),
          // Live progress sweep while this task is being prepared.
          AnimatedSize(
            duration: AppDurations.fast,
            child: working
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(top: 8, start: 52),
                    child: ClipRRect(
                      borderRadius: AppRadii.pillAll,
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.8))),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: const [Color(0xFF89CFF0), Color(0xFF3F97DA), Color(0xFF89CFF0)],
                                    stops: [0, shimmer, 1],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

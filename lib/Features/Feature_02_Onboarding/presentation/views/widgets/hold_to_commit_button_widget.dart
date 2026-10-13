import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';

/// Circular fingerprint "seal": press and hold to commit.
///
/// * Idle — a glass disc with a soft fingerprint and calm pulse rings that
///   invite the touch.
/// * Holding — the disc sinks slightly, a sky progress ring sweeps around it,
///   the ridges light up from the core outward while a scan beam glides over
///   them, with a haptic tick every quarter. Releasing early drains it back.
/// * Sealed — the disc fills with sky, the fingerprint melts into a check mark
///   and a ripple bursts outward.
///
/// The whole block (disc + label) is the touch target, so it's easy to hold.
class HoldToCommitButtonWidget extends StatefulWidget {
  const HoldToCommitButtonWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.completedLabel,
    required this.onCommitted,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.isCompleted = false,
    this.onProgressChanged,
  });

  final String label;
  final String hint;
  final String completedLabel;
  final VoidCallback onCommitted;
  final Duration holdDuration;
  final bool isCompleted;

  /// 0 … 1 hold progress, reported every frame (drives the commitment scene).
  final ValueChanged<double>? onProgressChanged;

  @override
  State<HoldToCommitButtonWidget> createState() => _HoldToCommitButtonWidgetState();
}

class _HoldToCommitButtonWidgetState extends State<HoldToCommitButtonWidget> with TickerProviderStateMixin {
  static const double _discSize = 96;
  static const double _canvasSize = 148;

  late final AnimationController _hold =
      AnimationController(vsync: this, duration: widget.holdDuration, value: widget.isCompleted ? 1 : 0)
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);

  /// Ambient loop: idle pulse rings + scan beam.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  /// 0 → 1 seal animation (fingerprint → check, burst ripple).
  late final AnimationController _seal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: widget.isCompleted ? 1 : 0,
  );

  int _lastHapticQuarter = 0;
  bool _completed = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.isCompleted;
  }

  void _onTick() {
    widget.onProgressChanged?.call(_hold.value);
    final quarter = (_hold.value * 4).floor();
    if (_hold.status == AnimationStatus.forward && quarter > _lastHapticQuarter) AppFunctions.lightHaptic();
    _lastHapticQuarter = quarter;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      setState(() {
        _completed = true;
        _pressed = false;
      });
      AppFunctions.successHaptic();
      _seal.forward();
      widget.onCommitted();
    }
  }

  void _startHold() {
    if (_completed) return;
    setState(() => _pressed = true);
    _hold.forward();
  }

  void _cancelHold() {
    if (_completed) return;
    setState(() => _pressed = false);
    _hold.animateBack(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _hold.dispose();
    _ambient.dispose();
    _seal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _completed ? widget.completedLabel : '${widget.label}. ${widget.hint}',
      onTap: _completed ? null : _hold.forward,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _startHold(),
        onPointerUp: (_) => _cancelHold(),
        onPointerCancel: (_) => _cancelHold(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Press feel: the disc sinks a touch while held.
            AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: SizedBox.square(
                dimension: _canvasSize,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FingerprintSealPainter(
                      hold: _hold,
                      ambient: _ambient,
                      seal: _seal,
                      discRadius: _discSize / 2,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppDurations.medium,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(animation), child: child),
              ),
              child: Text(
                _completed ? widget.completedLabel : widget.label,
                key: ValueKey(_completed),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(color: _completed ? AppColors.primaryInk : AppColors.ink),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedOpacity(
              opacity: _completed ? 0 : 1,
              duration: AppDurations.fast,
              child: Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FingerprintSealPainter extends CustomPainter {
  _FingerprintSealPainter({required this.hold, required this.ambient, required this.seal, required this.discRadius})
    : super(repaint: Listenable.merge([hold, ambient, seal]));

  final Animation<double> hold;
  final Animation<double> ambient;
  final Animation<double> seal;
  final double discRadius;

  static const int _ridgeCount = 6;

  /// Resting ridge colour (soft slate) — ridges turn white as they light up.
  static final Color _idleRidge = Color.lerp(AppColors.inkMuted, AppColors.primaryInk, 0.35)!.withValues(alpha: 0.6);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final progress = Curves.easeInOut.transform(hold.value);
    final sealT = seal.value;
    final sealed = sealT > 0;

    _paintPulseRings(canvas, center, progress, sealT);
    _paintBurst(canvas, center, sealT);

    // Disc: white glass that fills with sky as the hold progresses / seals.
    final discRect = Rect.fromCircle(center: center, radius: discRadius);
    canvas.drawCircle(
      center.translate(0, 8),
      discRadius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.18 + 0.22 * math.max(progress, sealT))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(center, discRadius, Paint()..color = Colors.white.withValues(alpha: 0.96));
    final fill = math.max(progress * 0.85, sealT);
    if (fill > 0) {
      canvas.drawCircle(
        center,
        discRadius,
        Paint()
          // The paint's alpha fades the gradient in.
          ..color = Colors.white.withValues(alpha: fill)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9E4FA), Color(0xFF5AAFE6)],
          ).createShader(discRect),
      );
    }
    canvas.drawCircle(
      center,
      discRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );

    // Progress ring around the disc.
    final ringRadius = discRadius + 9;
    if (!sealed) {
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = AppColors.primarySoft.withValues(alpha: 0.9),
      );
    }
    final sweep = sealed ? 1.0 - sealT : progress; // the ring dissolves into the burst
    if (sweep > 0) {
      final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        (sealed ? 1.0 : sweep) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: sealed ? sweep : 1)
          ..shader = const SweepGradient(
            transform: GradientRotation(-math.pi / 2),
            colors: [Color(0xFF89CFF0), Color(0xFF3F97DA), Color(0xFF89CFF0)],
          ).createShader(ringRect),
      );
      // Glowing head of the ring.
      if (!sealed) {
        final angle = -math.pi / 2 + sweep * 2 * math.pi;
        final head = center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
        canvas
          ..drawCircle(
            head,
            7,
            Paint()
              ..color = AppColors.primary.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          )
          ..drawCircle(head, 3.6, Paint()..color = Colors.white);
      }
    }

    // Fingerprint (fades out as the check draws in).
    final printOpacity = 1 - Curves.easeIn.transform((sealT * 1.6).clamp(0.0, 1.0));
    if (printOpacity > 0) _paintFingerprint(canvas, center, progress, printOpacity);
    if (!sealed && progress > 0) _paintScanBeam(canvas, center, progress);
    if (sealed) _paintCheck(canvas, center, sealT);
  }

  void _paintPulseRings(Canvas canvas, Offset center, double progress, double sealT) {
    final strength = (1 - progress) * (1 - sealT);
    if (strength <= 0) return;
    for (var i = 0; i < 2; i++) {
      final t = (ambient.value + i * 0.5) % 1;
      final radius = lerpDouble(discRadius, discRadius * 1.48, Curves.easeOut.transform(t))!;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.primary.withValues(alpha: (1 - t) * 0.55 * strength),
      );
    }
  }

  void _paintBurst(Canvas canvas, Offset center, double sealT) {
    if (sealT <= 0 || sealT >= 1) return;
    final t = Curves.easeOutCubic.transform(sealT);
    canvas.drawCircle(
      center,
      lerpDouble(discRadius, discRadius * 1.5, t)!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(6, 1, t)!
        ..color = AppColors.primary.withValues(alpha: (1 - t) * 0.8),
    );
  }

  /// Organic whorl: concentric open arcs (each with one natural break),
  /// lighting up from the core outward as [progress] grows.
  void _paintFingerprint(Canvas canvas, Offset center, double progress, double opacity) {
    final core = center.translate(0, 5);
    final scale = discRadius / 48;
    final front = progress * (_ridgeCount + 1);

    Paint ridgePaint(double lit) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * scale
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(_idleRidge, Colors.white, lit)!.withValues(alpha: opacity * (0.6 + 0.4 * lit));

    // Core stroke.
    canvas.drawLine(core.translate(0, -2 * scale), core.translate(0, 6 * scale), ridgePaint(front.clamp(0.0, 1.0)));

    for (var i = 0; i < _ridgeCount; i++) {
      final ry = (7.0 + i * 5.6) * scale;
      final rx = ry * 0.84;
      final rect = Rect.fromCenter(center: core, width: rx * 2, height: ry * 2);
      final paint = ridgePaint((front - i - 1).clamp(0.0, 1.0));

      // Open at the bottom; each ring broken once at a staggered angle.
      final start = math.pi * (0.92 - i * 0.025);
      final end = math.pi * (2.08 + i * 0.025);
      final gapAt = math.pi * (1.18 + (i.isEven ? 0.42 : 0.12) + i * 0.03);
      const gap = 0.32;
      canvas
        ..drawArc(rect, start, gapAt - gap / 2 - start, false, paint)
        ..drawArc(rect, gapAt + gap / 2, end - gapAt - gap / 2, false, paint);
    }
  }

  void _paintScanBeam(Canvas canvas, Offset center, double progress) {
    final travel = discRadius * 0.7;
    final y = center.dy + math.sin(ambient.value * 2 * math.pi * 2) * travel;
    final beam = Rect.fromCenter(center: Offset(center.dx, y), width: discRadius * 2, height: 18);
    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: discRadius - 1)))
      ..drawRect(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.6 * (1 - progress * 0.4)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(beam),
      )
      ..restore();
  }

  void _paintCheck(Canvas canvas, Offset center, double sealT) {
    final t = Curves.easeOutCubic.transform(((sealT - 0.25) / 0.75).clamp(0.0, 1.0));
    if (t <= 0) return;
    final s = discRadius / 48;
    final path = Path()
      ..moveTo(center.dx - 16 * s, center.dy + 1 * s)
      ..lineTo(center.dx - 5 * s, center.dy + 12 * s)
      ..lineTo(center.dx + 18 * s, center.dy - 12 * s);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _FingerprintSealPainter oldDelegate) => oldDelegate.discRadius != discRadius;
}

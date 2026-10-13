import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_mark_painter.dart';

/// Illustrated splash — "from dirty dishes to sparkle", drawn in code:
///
///  1. a kitchen counter with a white sink rises in; dirty plates and a mug
///     wait in the sink under a chrome faucet;
///  2. the faucet lever turns, a shimmering stream of water runs;
///  3. soap suds swell up and swallow the dishes, bubbles start drifting up;
///  4. the water stops, the foam settles — the dishes are clean & sparkle;
///  5. a big soap bubble rises from the sink carrying the Sinkly mark and
///     POPS (ring + droplets) — the lock clicks open;
///  6. the wordmark and tagline glide in; suds keep drifting gently.
///
/// One master controller drives the whole story; an ambient loop keeps the
/// water, foam and bubbles alive afterwards.
class SplashKitchenSceneWidget extends StatefulWidget {
  const SplashKitchenSceneWidget({super.key});

  /// Time until the whole story has played (used by the splash gate).
  static const Duration totalDuration = Duration(milliseconds: 4600);

  @override
  State<SplashKitchenSceneWidget> createState() => _SplashKitchenSceneWidgetState();
}

class _SplashKitchenSceneWidgetState extends State<SplashKitchenSceneWidget> with TickerProviderStateMixin {
  late final AnimationController _story = AnimationController(vsync: this, duration: const Duration(milliseconds: 4300))
    ..forward();

  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  bool _waterHaptic = false;
  bool _popHaptic = false;

  @override
  void initState() {
    super.initState();
    _story.addListener(() {
      final t = _story.value;
      if (!_waterHaptic && t >= _Beats.waterOn) {
        _waterHaptic = true;
        AppFunctions.lightHaptic();
      }
      if (!_popHaptic && t >= _Beats.pop) {
        _popHaptic = true;
        AppFunctions.mediumHaptic();
      }
    });
  }

  @override
  void dispose() {
    _story.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final sceneHeight = math.min(height * 0.44, width * 1.0);
        final tileSize = math.min(132.0, width * 0.34);
        final logoCenter = Offset(width / 2, topInset + height * 0.2 + tileSize / 2);
        final sinkMouth = Offset(width / 2, height - sceneHeight + sceneHeight * 0.5);

        return AnimatedBuilder(
          animation: Listenable.merge([_story, _ambient]),
          builder: (context, _) {
            final t = _story.value;
            final ambientSeconds = _ambient.value * 6 + t * 4.3;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Suds drifting up across the whole screen.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RisingBubblesPainter(t: t, seconds: ambientSeconds, origin: sinkMouth),
                  ),
                ),
                // Logo + wordmark + tagline.
                Positioned(
                  left: 0,
                  right: 0,
                  top: logoCenter.dy - tileSize / 2,
                  child: _BrandLockup(t: t, seconds: ambientSeconds, tileSize: tileSize),
                ),
                // The kitchen sink scene.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: sceneHeight,
                  child: Transform.translate(
                    offset: Offset(0, sceneHeight * 0.35 * (1 - Curves.easeOutCubic.transform(_Beats.seg(t, 0, 0.16)))),
                    child: Opacity(
                      opacity: _Beats.seg(t, 0, 0.1),
                      child: CustomPaint(
                        painter: _KitchenSinkPainter(t: t, seconds: ambientSeconds),
                      ),
                    ),
                  ),
                ),
                // The hero bubble carrying the logo, and its pop.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _HeroBubblePainter(t: t, from: sinkMouth, to: logoCenter, radius: tileSize * 0.72),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Story beats (fractions of the master timeline).
abstract final class _Beats {
  static const double waterOn = 0.14;
  static const double waterOff = 0.48;
  static const double cleanAt = 0.5;
  static const double bubbleStart = 0.52;
  static const double pop = 0.7;

  static double seg(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

  /// 0 → 1 (peak) → 0.5 (settled) foam level.
  static double foam(double t) {
    final rise = Curves.easeOutCubic.transform(seg(t, 0.18, 0.46));
    final settle = Curves.easeInOut.transform(seg(t, 0.48, 0.66));
    return rise * (1 - 0.48 * settle);
  }
}

// ── Brand lockup ────────────────────────────────────────────────────────

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.t, required this.seconds, required this.tileSize});

  final double t;
  final double seconds;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    // Inside the rising bubble the tile is small & soft; at the pop it springs.
    final arrive = _Beats.seg(t, 0.6, _Beats.pop);
    final spring = _Beats.seg(t, _Beats.pop, 0.8);
    final scale = t < _Beats.pop
        ? lerpDouble(0.35, 0.82, Curves.easeOut.transform(arrive))!
        : lerpDouble(0.82, 1, Curves.elasticOut.transform(spring))!;
    final tileOpacity = _Beats.seg(t, 0.6, 0.66);
    // The mark's own story (closed → key turn → click → water) after the pop.
    final markIntro = lerpDouble(0.16, 1, _Beats.seg(t, _Beats.pop, 0.97))!;
    final wordmark = Curves.easeOutCubic.transform(_Beats.seg(t, 0.8, 0.9));
    final tagline = Curves.easeOutCubic.transform(_Beats.seg(t, 0.86, 0.96));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: tileOpacity,
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tileSize * 0.23),
                boxShadow: [
                  BoxShadow(
                    color: SinklyLogoMarkPainter.skyBottom.withValues(alpha: 0.4 * spring),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: tileSize,
                child: CustomPaint(
                  painter: SinklyLogoMarkPainter(intro: markIntro, idle: t >= 1 ? seconds : 0, showSuds: true),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Opacity(
          opacity: wordmark,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - wordmark)),
            child: Text('Sinkly', style: AppTextStyles.display.copyWith(fontSize: 42, letterSpacing: -1.2)),
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: tagline,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - tagline)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(context.tr('splash_tagline'), style: AppTextStyles.body, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Soap bubble rendering ──────────────────────────────────────────────

/// Clear body, rainbow-sheen rim, white highlight.
void _paintSoapBubble(Canvas canvas, Offset center, double radius, double opacity, double hue) {
  if (radius <= 0.5 || opacity <= 0) return;
  final rect = Rect.fromCircle(center: center, radius: radius);
  canvas
    ..drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04 * opacity),
            Colors.white.withValues(alpha: 0.32 * opacity),
          ],
          stops: const [0.62, 1],
        ).createShader(rect),
    )
    ..drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, radius * 0.08)
        ..shader = SweepGradient(
          transform: GradientRotation(hue),
          colors: [
            const Color(0xFFFF9BB3).withValues(alpha: 0.7 * opacity),
            const Color(0xFF89CFF0).withValues(alpha: 0.75 * opacity),
            const Color(0xFF9FE6C8).withValues(alpha: 0.65 * opacity),
            const Color(0xFFFFE29A).withValues(alpha: 0.65 * opacity),
            const Color(0xFFC9B8FF).withValues(alpha: 0.75 * opacity),
            const Color(0xFFFF9BB3).withValues(alpha: 0.7 * opacity),
          ],
        ).createShader(rect),
    )
    ..drawArc(
      rect.deflate(radius * 0.26),
      math.pi * 1.1,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, radius * 0.14)
        ..color = Colors.white.withValues(alpha: 0.85 * opacity),
    );
}

/// Suds rising from the sink across the screen once the foam builds.
class _RisingBubblesPainter extends CustomPainter {
  _RisingBubblesPainter({required this.t, required this.seconds, required this.origin});

  final double t;
  final double seconds;
  final Offset origin;

  static final List<({double x, double radius, double speed, double offset, double sway})> _bubbles = () {
    final random = math.Random(21);
    return [
      for (var i = 0; i < 22; i++)
        (
          x: (random.nextDouble() - 0.5) * 1.15,
          radius: 4 + random.nextDouble() * 14,
          speed: 0.12 + random.nextDouble() * 0.12,
          offset: random.nextDouble(),
          sway: 6 + random.nextDouble() * 14,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final strength = Curves.easeOut.transform(_Beats.seg(t, 0.3, 0.5));
    if (strength <= 0) return;
    final travel = origin.dy + 60;
    for (final (index, bubble) in _bubbles.indexed) {
      final cycle = (seconds * bubble.speed + bubble.offset) % 1;
      final y = origin.dy - cycle * travel;
      final x = origin.dx + bubble.x * size.width * 0.5 * (0.4 + cycle) + math.sin(cycle * 9 + index) * bubble.sway;
      final fade = math.sin(cycle * math.pi).clamp(0.0, 1.0);
      _paintSoapBubble(canvas, Offset(x, y), bubble.radius, fade * strength * 0.9, cycle * 4 + index);
    }
  }

  @override
  bool shouldRepaint(covariant _RisingBubblesPainter oldDelegate) => true;
}

/// The big bubble that carries the logo up from the sink, then pops.
class _HeroBubblePainter extends CustomPainter {
  _HeroBubblePainter({required this.t, required this.from, required this.to, required this.radius});

  final double t;
  final Offset from;
  final Offset to;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rise = _Beats.seg(t, _Beats.bubbleStart, _Beats.pop);
    if (rise > 0 && t < _Beats.pop) {
      final k = Curves.easeInOutCubic.transform(rise);
      final position =
          Offset.lerp(from, to, k)! + Offset(math.sin(rise * math.pi * 3) * 10 * (1 - k), 0); // gentle wobble
      final r = lerpDouble(radius * 0.25, radius, Curves.easeOut.transform(rise))!;
      // Slightly squashed while rising (soap film physics, stylized).
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..scale(1 + 0.05 * math.sin(rise * math.pi * 4), 1 - 0.05 * math.sin(rise * math.pi * 4))
        ..translate(-position.dx, -position.dy);
      _paintSoapBubble(canvas, position, r, 1, rise * 6);
      canvas.restore();
    }

    // Pop: a ring bursts out and droplets fly.
    final pop = _Beats.seg(t, _Beats.pop, _Beats.pop + 0.1);
    if (pop > 0 && pop < 1) {
      final k = Curves.easeOutCubic.transform(pop);
      canvas.drawCircle(
        to,
        radius * (1 + 0.55 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - k) + 0.5
          ..color = AppColors.primary.withValues(alpha: 0.8 * (1 - k)),
      );
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 + 0.2;
        final distance = radius * (0.9 + 0.8 * k);
        final droplet = to + Offset(math.cos(angle), math.sin(angle)) * distance + Offset(0, 18 * k * k);
        canvas.drawCircle(
          droplet,
          (i.isEven ? 4.0 : 2.6) * (1 - k * 0.6),
          Paint()..color = (i.isEven ? const Color(0xFF89CFF0) : Colors.white).withValues(alpha: 1 - k),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroBubblePainter oldDelegate) => true;
}

// ── The kitchen sink scene ─────────────────────────────────────────────

class _KitchenSinkPainter extends CustomPainter {
  _KitchenSinkPainter({required this.t, required this.seconds});

  final double t;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final counterTop = h * 0.5;
    final band = h * 0.2; // visible counter top surface (3/4 view)
    final opening = Rect.fromCenter(
      center: Offset(w / 2, counterTop + band * 0.5),
      width: math.min(w * 0.66, 320),
      height: band * 0.82,
    );
    final unit = opening.width / 300; // scale everything from the sink width

    _paintBacksplash(canvas, size, counterTop);
    _paintCounter(canvas, size, counterTop, band);

    // Inside of the basin (depth).
    final basin = RRect.fromRectAndRadius(opening, Radius.circular(opening.height / 2));
    canvas
      ..drawRRect(
        basin,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9CC9EA), Color(0xFFD9ECF8)],
          ).createShader(opening),
      )
      ..drawRRect(
        basin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * unit
          ..color = Colors.white,
      );

    _paintFaucet(canvas, opening, unit);

    // Items in the sink are hidden below the front lip of the opening.
    final inSink = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, opening.center.dy)
      ..lineTo(opening.right, opening.center.dy)
      ..arcTo(opening, 0, math.pi, false)
      ..lineTo(0, opening.center.dy)
      ..close();
    canvas
      ..save()
      ..clipPath(inSink);
    _paintWaterStream(canvas, opening, unit);
    _paintDishes(canvas, opening, unit);
    _paintFoam(canvas, opening, unit);
    canvas.restore();

    // Foam spilling a little over the front lip at its peak.
    _paintFrontFoam(canvas, opening, unit);
    _paintSparkles(canvas, opening, unit);
  }

  void _paintBacksplash(Canvas canvas, Size size, double counterTop) {
    final tile = size.width / 7;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var row = 0; row * tile < counterTop; row++) {
      final y = counterTop - (row + 1) * tile;
      // Tiles fade out upward into the sky background.
      final alpha = (0.55 - row * 0.18).clamp(0.0, 1.0);
      if (alpha <= 0) break;
      paint.color = Colors.white.withValues(alpha: alpha);
      final shift = row.isOdd ? tile / 2 : 0.0;
      for (var x = -tile + shift; x < size.width; x += tile) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 3, y + 3, tile - 6, tile - 6), const Radius.circular(8)),
          paint,
        );
      }
    }
  }

  void _paintCounter(Canvas canvas, Size size, double counterTop, double band) {
    final w = size.width;
    final h = size.height;
    // Top surface.
    canvas.drawRect(
      Rect.fromLTWH(0, counterTop, w, band),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FC)],
        ).createShader(Rect.fromLTWH(0, counterTop, w, band)),
    );
    // Front face.
    final front = Rect.fromLTWH(0, counterTop + band, w, h - counterTop - band);
    canvas
      ..drawRect(
        front,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD4E7F6), Color(0xFFB7D5EE)],
          ).createShader(front),
      )
      // Edge highlight + soft shadow under the lip.
      ..drawLine(
        Offset(0, counterTop + band),
        Offset(w, counterTop + band),
        Paint()
          ..strokeWidth = 2
          ..color = Colors.white,
      )
      ..drawRect(
        Rect.fromLTWH(0, counterTop + band + 1, w, 10),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF7FA9CF).withValues(alpha: 0.35), const Color(0x007FA9CF)],
          ).createShader(Rect.fromLTWH(0, counterTop + band + 1, w, 10)),
      );
    // Cabinet doors.
    final doorTop = counterTop + band + 18;
    final doorWidth = w * 0.4;
    for (final x in [w * 0.08, w * 0.52]) {
      final door = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, doorTop, doorWidth, h - doorTop + 30),
        const Radius.circular(14),
      );
      canvas
        ..drawRRect(
          door,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.7),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + doorWidth / 2, doorTop + 20), width: 34, height: 5),
            const Radius.circular(3),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
    }
  }

  void _paintFaucet(Canvas canvas, Rect opening, double unit) {
    final base = Offset(opening.center.dx - opening.width * 0.28, opening.top + 2 * unit);
    final top = base.dy - 112 * unit;
    final spoutX = opening.center.dx + 6 * unit;
    final neck = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx, top + 30 * unit)
      ..arcToPoint(Offset(base.dx + 60 * unit, top + 30 * unit), radius: Radius.circular(30 * unit))
      ..lineTo(spoutX + 4 * unit, top + 30 * unit)
      ..lineTo(spoutX + 4 * unit, top + 48 * unit);
    final chrome = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFCFE4F3), Color(0xFF9FC4E2), Color(0xFFE8F4FC)],
        stops: [0, 0.4, 0.7, 1],
      ).createShader(Rect.fromLTRB(base.dx - 20, top, spoutX + 30, base.dy));
    canvas
      ..drawPath(neck, chrome)
      // Base plate.
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: base, width: 34 * unit, height: 12 * unit),
          Radius.circular(6 * unit),
        ),
        Paint()..color = const Color(0xFFE3F0FA),
      );
    // Lever turns on (and back off) with the water.
    final on = Curves.easeOutBack.transform(_Beats.seg(t, _Beats.waterOn - 0.06, _Beats.waterOn));
    final off = Curves.easeInOut.transform(_Beats.seg(t, _Beats.waterOff, _Beats.waterOff + 0.05));
    final angle = (-0.9 * on + 0.9 * off);
    final pivot = base.translate(-14 * unit, -26 * unit);
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle)
      ..drawLine(
        Offset.zero,
        Offset(-26 * unit, -6 * unit),
        Paint()
          ..strokeWidth = 8 * unit
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFDCEBF7),
      )
      ..restore()
      ..drawCircle(pivot, 7 * unit, Paint()..color = const Color(0xFFEAF5FC));
  }

  void _paintWaterStream(Canvas canvas, Rect opening, double unit) {
    final start = _Beats.seg(t, _Beats.waterOn, _Beats.waterOn + 0.05);
    final stop = _Beats.seg(t, _Beats.waterOff, _Beats.waterOff + 0.06);
    if (start <= 0 || stop >= 1) return;
    final spout = Offset(opening.center.dx + 10 * unit, opening.top - 64 * unit);
    final bottom = opening.center.dy + 6 * unit;
    final top = lerpDouble(spout.dy, bottom, stop)!; // the tail falls when it stops
    final end = lerpDouble(spout.dy, bottom, Curves.easeIn.transform(start))!;
    final stream = Rect.fromLTRB(spout.dx - 4 * unit, top, spout.dx + 4 * unit, end);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stream, Radius.circular(4 * unit)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xCC89CFF0), Color(0xFFE8F6FD), Color(0xCC5AAFE6)])
            .createShader(stream),
    );
    // Moving glints along the stream.
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      final y = top + ((seconds * 1.6 + i / 3) % 1) * (end - top);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(spout.dx - 1.5 * unit, y, 3 * unit, 10 * unit),
          Radius.circular(2 * unit),
        ),
        glint,
      );
    }
    // Splash where it lands.
    final splash = (seconds * 2.4) % 1;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(spout.dx, bottom),
        width: (20 + 26 * splash) * unit,
        height: (6 + 7 * splash) * unit,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * unit
        ..color = Colors.white.withValues(alpha: (1 - splash) * 0.9 * (1 - stop)),
    );
  }

  /// Plates standing in the sink + a mug; smudges wash off at [_Beats.cleanAt].
  void _paintDishes(Canvas canvas, Rect opening, double unit) {
    final clean = Curves.easeOut.transform(_Beats.seg(t, _Beats.cleanAt, _Beats.cleanAt + 0.08));
    final plates = [(dx: -46.0, r: 44.0, tilt: -0.18), (dx: -6.0, r: 50.0, tilt: 0.05), (dx: 38.0, r: 42.0, tilt: 0.2)];
    for (final (index, plate) in plates.indexed) {
      final center = Offset(opening.center.dx + plate.dx * unit, opening.center.dy - plate.r * 0.45 * unit);
      final r = plate.r * unit;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(plate.tilt)
        ..translate(-center.dx, -center.dy)
        ..drawCircle(
          center,
          r,
          Paint()
            ..shader = const RadialGradient(colors: [Colors.white, Color(0xFFEAF4FB)])
                .createShader(Rect.fromCircle(center: center, radius: r)),
        )
        ..drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * unit
            ..color = const Color(0xFFC9DFF0),
        )
        ..drawCircle(
          center,
          r * 0.66,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * unit
            ..color = const Color(0xFF89CFF0).withValues(alpha: 0.6),
        );
      // Dirty smudges that fade away when clean.
      final dirt = 1 - clean;
      if (dirt > 0) {
        final colors = [const Color(0xFFC79A6B), const Color(0xFF9CB36B), const Color(0xFFD98C6C)];
        for (var s = 0; s < 3; s++) {
          final a = s * 2.1 + index;
          canvas.drawOval(
            Rect.fromCenter(
              center: center + Offset(math.cos(a), math.sin(a)) * r * 0.4,
              width: (14 - s * 3) * unit,
              height: (9 - s * 2) * unit,
            ),
            Paint()..color = colors[(s + index) % 3].withValues(alpha: 0.85 * dirt),
          );
        }
      }
      // Shine sweep once clean.
      if (clean > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r * 0.82),
          math.pi * 1.1,
          math.pi * 0.35,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 4 * unit
            ..color = Colors.white.withValues(alpha: 0.9 * clean),
        );
      }
      canvas.restore();
    }

    // Mug on the right.
    final mug = Rect.fromLTWH(opening.center.dx + 64 * unit, opening.center.dy - 50 * unit, 34 * unit, 44 * unit);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(mug, Radius.circular(8 * unit)), Paint()..color = const Color(0xFFFFD6E0))
      ..drawArc(
        Rect.fromLTWH(mug.right - 8 * unit, mug.top + 10 * unit, 18 * unit, 20 * unit),
        -math.pi / 2,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * unit
          ..color = const Color(0xFFFFC1D1),
      )
      ..drawRect(
        Rect.fromLTWH(mug.left + 6 * unit, mug.top + 6 * unit, 5 * unit, mug.height - 16 * unit),
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
  }

  /// Foam cloud that swells over the dishes, then settles.
  void _paintFoam(Canvas canvas, Rect opening, double unit) {
    final level = _Beats.foam(t);
    if (level <= 0) return;
    final random = math.Random(5);
    for (var i = 0; i < 26; i++) {
      final along = random.nextDouble();
      final x = opening.left + opening.width * (0.06 + 0.88 * along);
      final heightFactor = math.sin(along * math.pi); // taller in the middle
      final base = opening.center.dy + 4 * unit;
      final y = base - (10 + 70 * heightFactor * random.nextDouble()) * unit * level;
      final r = (10 + random.nextDouble() * 16) * unit * (0.4 + 0.6 * level);
      final wobble = math.sin(seconds * 2.4 + i) * 1.5 * unit;
      _paintFoamPuff(canvas, Offset(x + wobble, y), r);
    }
  }

  void _paintFrontFoam(Canvas canvas, Rect opening, double unit) {
    final level = _Beats.foam(t);
    if (level <= 0.3) return;
    final k = ((level - 0.3) / 0.7).clamp(0.0, 1.0);
    for (final (dx, size) in const [(-0.32, 14.0), (-0.1, 11.0), (0.18, 16.0), (0.38, 10.0)]) {
      final center = Offset(opening.center.dx + dx * opening.width, opening.bottom - 2 * unit);
      _paintFoamPuff(canvas, center + Offset(0, math.sin(seconds * 2 + dx * 10) * unit), size * unit * k);
    }
  }

  static void _paintFoamPuff(Canvas canvas, Offset center, double r) {
    if (r <= 0.5) return;
    canvas
      ..drawCircle(center, r, Paint()..color = Colors.white)
      ..drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFFCFE4F3),
      )
      ..drawCircle(center + Offset(-r * 0.35, -r * 0.35), r * 0.22, Paint()..color = const Color(0xFFE8F6FD));
  }

  void _paintSparkles(Canvas canvas, Rect opening, double unit) {
    final appear = _Beats.seg(t, _Beats.cleanAt + 0.04, _Beats.cleanAt + 0.16);
    if (appear <= 0) return;
    final spots = [
      Offset(opening.center.dx - 60 * unit, opening.top - 50 * unit),
      Offset(opening.center.dx + 30 * unit, opening.top - 66 * unit),
      Offset(opening.center.dx + 90 * unit, opening.top - 30 * unit),
    ];
    for (final (index, spot) in spots.indexed) {
      final twinkle = 0.75 + 0.25 * math.sin(seconds * 3 + index * 2);
      final scale = Curves.easeOutBack.transform(appear) * twinkle;
      _sparkle(canvas, spot, (index == 1 ? 11 : 7) * unit * scale);
    }
  }

  static void _sparkle(Canvas canvas, Offset c, double r) {
    if (r <= 0) return;
    final k = r * 0.18;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(c.dx + k, c.dy - k, c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..cubicTo(c.dx + k, c.dy + k, c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..cubicTo(c.dx - k, c.dy + k, c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..cubicTo(c.dx - k, c.dy - k, c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = Colors.white)
      ..drawCircle(
        c,
        r * 0.9,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
  }

  @override
  bool shouldRepaint(covariant _KitchenSinkPainter oldDelegate) => true;
}

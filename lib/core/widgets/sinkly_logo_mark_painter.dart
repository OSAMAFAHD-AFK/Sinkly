import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The Sinkly "Sink-Lock" mark: a padlock whose body is a glossy sink basin
/// and whose shackle is the faucet. A drop falls, the basin fills and the
/// shackle lifts open — "clean the sink → your apps unlock".
///
/// Drawn in a 200 × 200 design space. [intro] runs 0 → 1 for the splash
/// sequence (1 = final, slightly-open lock); [idle] is seconds since the
/// intro finished and drives the gentle water sway + sparkle twinkle.
class SinklyLogoMarkPainter extends CustomPainter {
  SinklyLogoMarkPainter({
    this.intro = 1,
    this.idle = 0,
    this.background = SinklyLogoBackground.roundedTile,
    this.glyphScale = 1,
    this.showGlyph = true,
    super.repaint,
  });

  final double intro;
  final double idle;
  final SinklyLogoBackground background;

  /// Shrinks the glyph inside the tile (adaptive icons / circular avatars).
  final double glyphScale;

  /// `false` paints only the sky backdrop (Android adaptive-icon background
  /// layer — the glyph lives in the separate foreground layer).
  final bool showGlyph;

  static const double designSize = 200;
  static const Color navy = Color(0xFF26305A);
  static const Color skyTop = Color(0xFFB9E4FA);
  static const Color skyBottom = Color(0xFF5AAFE6);

  static const Rect _design = Rect.fromLTWH(0, 0, designSize, designSize);
  static final Path _bowl = Path()
    ..moveTo(54, 106)
    ..lineTo(146, 106)
    ..cubicTo(146, 146, 126, 166, 100, 166)
    ..cubicTo(74, 166, 54, 146, 54, 106)
    ..close();

  /// Maps [t] from the window [start, end] to 0…1.
  static double _seg(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / designSize, size.height / designSize);

    // Whole mark pops in.
    final pop = _seg(intro, 0, 0.25);
    final popScale = pop < 0.7
        ? lerpDouble(0.6, 1.06, Curves.easeOut.transform(pop / 0.7))!
        : lerpDouble(1.06, 1, (pop - 0.7) / 0.3)!;
    canvas
      ..translate(100, 100)
      ..scale(popScale)
      ..translate(-100, -100);
    final fade = (pop * 3).clamp(0.0, 1.0);
    canvas.saveLayer(_design, Paint()..color = Colors.white.withValues(alpha: fade));

    _paintBackground(canvas);

    if (!showGlyph) {
      canvas
        ..restore()
        ..restore();
      return;
    }

    canvas
      ..translate(100, 104)
      ..scale(glyphScale)
      ..translate(-100, -104);
    _paintShackle(canvas);
    _paintBasin(canvas);
    _paintDrop(canvas);
    _paintKeyhole(canvas);
    _paintSparkles(canvas);

    canvas
      ..restore()
      ..restore();
  }

  void _paintBackground(Canvas canvas) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyBottom],
      ).createShader(_design);
    switch (background) {
      case SinklyLogoBackground.roundedTile:
        canvas.drawRRect(RRect.fromRectAndRadius(_design, const Radius.circular(46)), paint);
      case SinklyLogoBackground.square:
        canvas.drawRect(_design, paint);
      case SinklyLogoBackground.circle:
        canvas.drawCircle(const Offset(100, 100), 100, paint);
      case SinklyLogoBackground.none:
        return;
    }
    // Soft glass gloss across the top.
    canvas.save();
    if (background == SinklyLogoBackground.circle) {
      canvas.clipPath(Path()..addOval(_design));
    } else if (background == SinklyLogoBackground.roundedTile) {
      canvas.clipRRect(RRect.fromRectAndRadius(_design, const Radius.circular(46)));
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 26), width: 168, height: 68),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  void _paintShackle(Canvas canvas) {
    // Closed (sunk 16 into the rim) → lifts with a little overshoot → rests
    // slightly open (rotated −10° around the left leg).
    final t = intro;
    double lift;
    double angle;
    if (t < 0.55) {
      lift = 16;
      angle = 0;
    } else if (t < 0.75) {
      final k = Curves.easeOutBack.transform(_seg(t, 0.55, 0.75));
      lift = lerpDouble(16, -3, k)!;
      angle = lerpDouble(0, -12, k)!;
    } else {
      final k = Curves.easeInOut.transform(_seg(t, 0.75, 1));
      lift = lerpDouble(-3, 0, k)!;
      angle = lerpDouble(-12, -10, k)!;
    }

    canvas.save();
    canvas
      ..translate(72, 98 + lift)
      ..rotate(angle * math.pi / 180)
      ..translate(-72, -98);
    final shackle = Path()
      ..moveTo(72, 100)
      ..lineTo(72, 70)
      ..arcToPoint(const Offset(128, 70), radius: const Radius.circular(28))
      ..lineTo(128, 84);
    canvas.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE9F5FD), Color(0xFFBFDDF2)],
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTWH(58, 34, 84, 74)),
    );
    // Faucet spout tip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(119, 82, 18, 9), const Radius.circular(4.5)),
      Paint()..color = const Color(0xFFE9F5FD),
    );
    canvas.restore();
  }

  void _paintDrop(Canvas canvas) {
    final t = intro;
    if (t <= 0 || t >= 0.62) return;
    // Sky drop forms at the faucet tip, falls into the basin, then merges.
    final appear = Curves.easeOut.transform(_seg(t, 0.08, 0.25));
    final fall = Curves.easeIn.transform(_seg(t, 0.25, 0.55));
    final opacity = t < 0.55 ? appear : 1 - _seg(t, 0.55, 0.62);
    if (opacity <= 0) return;
    canvas.save();
    canvas
      ..translate(128, 104 + lerpDouble(-4, 0, appear)! + fall * 26)
      ..scale(lerpDouble(0.2, 1, appear)!)
      ..translate(-128, -108);
    final drop = Path()
      ..moveTo(128, 96)
      ..cubicTo(128, 96, 121, 105, 121, 110)
      ..arcToPoint(const Offset(135, 110), radius: const Radius.circular(7), clockwise: false)
      ..cubicTo(135, 105, 128, 96, 128, 96)
      ..close();
    canvas
      ..drawPath(
        drop,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8ED4F7).withValues(alpha: opacity),
              const Color(0xFF3F97DA).withValues(alpha: opacity),
            ],
          ).createShader(const Rect.fromLTWH(121, 96, 14, 21)),
      )
      ..drawCircle(const Offset(125.5, 110), 1.8, Paint()..color = Colors.white.withValues(alpha: 0.8 * opacity))
      ..restore();
  }

  void _paintBasin(Canvas canvas) {
    canvas.drawPath(
      _bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFDCEFFB)],
        ).createShader(const Rect.fromLTWH(54, 106, 92, 60)),
    );

    // Water rises inside the basin (clipped to the bowl) and sways at rest.
    final rise = _seg(intro, 0.45, 1);
    final lift = rise < 0.78
        ? lerpDouble(36, -2, Curves.easeOut.transform(rise / 0.78))!
        : lerpDouble(-2, 0, (rise - 0.78) / 0.22)!;
    final sway = -7 + math.cos(idle * 2 * math.pi / 3) * 7; // 0 at rest
    canvas.save();
    canvas.clipPath(_bowl);
    canvas.translate(sway, lift);
    final wave = Path()..moveTo(30, 136);
    for (var x = 30.0; x < 174; x += 24) {
      wave
        ..quadraticBezierTo(x + 6, 133, x + 12, 136)
        ..quadraticBezierTo(x + 18, 139, x + 24, 136);
    }
    final body = Path.from(wave)
      ..lineTo(174, 180)
      ..lineTo(30, 180)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8ED4F7), Color(0xFF3F97DA)],
        ).createShader(const Rect.fromLTWH(30, 132, 144, 48)),
    );
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.restore();

    // Splash ring where the drop lands.
    final ring = _seg(intro, 0.5, 1);
    if (ring > 0 && ring < 1) {
      final scale = lerpDouble(0.2, 1.6, ring)!;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(126, 136), width: 20 * scale, height: 6 * scale),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: (1 - ring) * 0.9),
      );
    }

    // Rim + highlight.
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(44, 96, 112, 16), const Radius.circular(8)),
        Paint()..color = Colors.white,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(50, 98, 70, 4), const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
  }

  void _paintKeyhole(Canvas canvas) {
    final keyPaint = Paint()..color = navy;
    canvas
      ..drawCircle(const Offset(100, 128), 7.5, keyPaint)
      ..drawPath(
        Path()
          ..moveTo(96, 131)
          ..lineTo(104, 131)
          ..lineTo(106.5, 147)
          ..lineTo(93.5, 147)
          ..close(),
        keyPaint,
      );
  }

  void _paintSparkles(Canvas canvas) {
    final twinkle = 0.8 + 0.2 * math.cos(idle * 2 * math.pi / 2.4); // 1 at rest
    _sparkle(canvas, const Offset(158, 52), 12, _popScale(_seg(intro, 0.73, 0.94)) * twinkle);
    _sparkle(canvas, const Offset(40, 70), 6, _popScale(_seg(intro, 0.81, 1)));
  }

  static double _popScale(double t) =>
      t < 0.6 ? lerpDouble(0, 1.25, Curves.easeOut.transform(t / 0.6))! : lerpDouble(1.25, 1, (t - 0.6) / 0.4)!;

  static void _sparkle(Canvas canvas, Offset c, double s, double scale) {
    if (scale <= 0) return;
    final r = s * scale;
    final k = r * 0.18;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(c.dx + k, c.dy - k, c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..cubicTo(c.dx + k, c.dy + k, c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..cubicTo(c.dx - k, c.dy + k, c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..cubicTo(c.dx - k, c.dy - k, c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant SinklyLogoMarkPainter oldDelegate) =>
      oldDelegate.intro != intro ||
      oldDelegate.idle != idle ||
      oldDelegate.background != background ||
      oldDelegate.glyphScale != glyphScale ||
      oldDelegate.showGlyph != showGlyph;
}

/// Shape of the sky backdrop behind the mark.
enum SinklyLogoBackground {
  /// App-icon tile with rounded corners (in-app use).
  roundedTile,

  /// Full-bleed square (iOS icon — the OS applies its own mask).
  square,

  /// Full circle (social avatars).
  circle,

  /// Glyph only (Android adaptive-icon foreground).
  none,
}

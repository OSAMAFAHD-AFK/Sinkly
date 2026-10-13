import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_category_model.dart';

/// Large, colorful category glyph inspired by Screen-Time / Opal pickers:
/// clear silhouette, saturated accent, soft padded tile.
class AppCategoryIconWidget extends StatelessWidget {
  const AppCategoryIconWidget({super.key, this.category, this.size = 44});

  /// `null` renders the stacked "All apps & categories" mark.
  final AppCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.background, Color.lerp(palette.background, Colors.white, 0.35)!],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CategoryGlyphPainter(category: category, accent: palette.accent, secondary: palette.secondary),
      ),
    );
  }
}

({Color background, Color accent, Color secondary}) _paletteFor(AppCategory? category) {
  return switch (category) {
    null => (background: const Color(0xFFEAF4FF), accent: const Color(0xFF4C8DFF), secondary: const Color(0xFFFF6B9D)),
    AppCategory.social => (
      background: const Color(0xFFFFE6F0),
      accent: const Color(0xFFFF4D8D),
      secondary: const Color(0xFF6BB7FF),
    ),
    AppCategory.games => (
      background: const Color(0xFFE8F0FF),
      accent: const Color(0xFF3B7CFF),
      secondary: const Color(0xFF9AD0FF),
    ),
    AppCategory.entertainment => (
      background: const Color(0xFFFFEBE8),
      accent: const Color(0xFFFF4B5C),
      secondary: const Color(0xFFFFF1F0),
    ),
    AppCategory.utilities => (
      background: const Color(0xFFEAF7F2),
      accent: const Color(0xFF2DB88A),
      secondary: const Color(0xFF1F2A37),
    ),
    AppCategory.creativity => (
      background: const Color(0xFFFFF0E4),
      accent: const Color(0xFFE28A3A),
      secondary: const Color(0xFFFF6B9D),
    ),
    AppCategory.productivity => (
      background: const Color(0xFFE8F4FF),
      accent: const Color(0xFF2F8CFF),
      secondary: const Color(0xFF7EC2FF),
    ),
    AppCategory.shoppingFood => (
      background: const Color(0xFFEAF3FF),
      accent: const Color(0xFF3B82F6),
      secondary: const Color(0xFFFFB020),
    ),
    AppCategory.education => (
      background: const Color(0xFFE8F7FF),
      accent: const Color(0xFF2BA3D6),
      secondary: const Color(0xFF57C46B),
    ),
    AppCategory.travel => (
      background: const Color(0xFFEAF9F2),
      accent: const Color(0xFF2F9E6B),
      secondary: const Color(0xFFFFC857),
    ),
    AppCategory.health => (
      background: const Color(0xFFEEF2F6),
      accent: const Color(0xFF5B6B80),
      secondary: const Color(0xFF89CFF0),
    ),
    AppCategory.reading => (
      background: const Color(0xFFEAF4FF),
      accent: const Color(0xFF5AA8E8),
      secondary: const Color(0xFFFFF8EE),
    ),
    AppCategory.other => (
      background: const Color(0xFFEEF1F5),
      accent: const Color(0xFF2B3545),
      secondary: const Color(0xFF89CFF0),
    ),
  };
}

class _CategoryGlyphPainter extends CustomPainter {
  const _CategoryGlyphPainter({required this.category, required this.accent, required this.secondary});

  final AppCategory? category;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide;
    switch (category) {
      case null:
        _paintAllStack(canvas, c, s);
      case AppCategory.social:
        _paintSocial(canvas, c, s);
      case AppCategory.games:
        _paintRocket(canvas, c, s);
      case AppCategory.entertainment:
        _paintPopcorn(canvas, c, s);
      case AppCategory.utilities:
        _paintCalculator(canvas, c, s);
      case AppCategory.creativity:
        _paintPalette(canvas, c, s);
      case AppCategory.productivity:
        _paintPlane(canvas, c, s);
      case AppCategory.shoppingFood:
        _paintBag(canvas, c, s);
      case AppCategory.education:
        _paintGlobe(canvas, c, s);
      case AppCategory.travel:
        _paintIsland(canvas, c, s);
      case AppCategory.health:
        _paintBike(canvas, c, s);
      case AppCategory.reading:
        _paintBook(canvas, c, s);
      case AppCategory.other:
        _paintPhone(canvas, c, s);
    }
  }

  void _paintAllStack(Canvas canvas, Offset c, double s) {
    final layers = <(Color, Offset)>[
      (const Color(0xFFFF6B9D), Offset(c.dx + s * 0.05, c.dy + s * 0.08)),
      (const Color(0xFFFFC857), Offset(c.dx, c.dy)),
      (const Color(0xFF4C8DFF), Offset(c.dx - s * 0.05, c.dy - s * 0.08)),
    ];
    for (final (color, center) in layers) {
      final rect = Rect.fromCenter(center: center, width: s * 0.52, height: s * 0.34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.1)),
        Paint()..color = color,
      );
    }
  }

  void _paintSocial(Canvas canvas, Offset c, double s) {
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -s * 0.02), width: s * 0.58, height: s * 0.48),
        Radius.circular(s * 0.18),
      ))
      ..moveTo(c.dx - s * 0.08, c.dy + s * 0.18)
      ..lineTo(c.dx - s * 0.18, c.dy + s * 0.32)
      ..lineTo(c.dx + s * 0.02, c.dy + s * 0.2)
      ..close();
    canvas.drawPath(bubble, Paint()..color = accent);
    // Heart.
    final heart = Path()
      ..moveTo(c.dx, c.dy + s * 0.04)
      ..cubicTo(c.dx - s * 0.16, c.dy - s * 0.08, c.dx - s * 0.14, c.dy - s * 0.18, c.dx, c.dy - s * 0.1)
      ..cubicTo(c.dx + s * 0.14, c.dy - s * 0.18, c.dx + s * 0.16, c.dy - s * 0.08, c.dx, c.dy + s * 0.04);
    canvas.drawPath(heart, Paint()..color = Colors.white);
    canvas.drawCircle(c.translate(s * 0.28, -s * 0.22), s * 0.08, Paint()..color = secondary);
    canvas.drawCircle(c.translate(s * 0.34, -s * 0.06), s * 0.055, Paint()..color = secondary.withValues(alpha: 0.75));
  }

  void _paintRocket(Canvas canvas, Offset c, double s) {
    final body = Path()
      ..moveTo(c.dx, c.dy - s * 0.32)
      ..quadraticBezierTo(c.dx + s * 0.16, c.dy - s * 0.05, c.dx + s * 0.12, c.dy + s * 0.18)
      ..lineTo(c.dx - s * 0.12, c.dy + s * 0.18)
      ..quadraticBezierTo(c.dx - s * 0.16, c.dy - s * 0.05, c.dx, c.dy - s * 0.32)
      ..close();
    canvas.drawPath(body, Paint()..color = accent);
    canvas.drawCircle(c.translate(0, -s * 0.02), s * 0.07, Paint()..color = Colors.white);
    final fin = Paint()..color = secondary;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.1, c.dy + s * 0.08)
        ..lineTo(c.dx - s * 0.26, c.dy + s * 0.22)
        ..lineTo(c.dx - s * 0.08, c.dy + s * 0.18)
        ..close(),
      fin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + s * 0.1, c.dy + s * 0.08)
        ..lineTo(c.dx + s * 0.26, c.dy + s * 0.22)
        ..lineTo(c.dx + s * 0.08, c.dy + s * 0.18)
        ..close(),
      fin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.06, c.dy + s * 0.18)
        ..lineTo(c.dx, c.dy + s * 0.34)
        ..lineTo(c.dx + s * 0.06, c.dy + s * 0.18)
        ..close(),
      Paint()..color = const Color(0xFFFF8A3D),
    );
  }

  void _paintPopcorn(Canvas canvas, Offset c, double s) {
    final bucket = Path()
      ..moveTo(c.dx - s * 0.22, c.dy - s * 0.02)
      ..lineTo(c.dx - s * 0.16, c.dy + s * 0.3)
      ..lineTo(c.dx + s * 0.16, c.dy + s * 0.3)
      ..lineTo(c.dx + s * 0.22, c.dy - s * 0.02)
      ..close();
    canvas.drawPath(bucket, Paint()..color = accent);
    for (var i = 0; i < 3; i++) {
      final x = c.dx - s * 0.14 + i * s * 0.14;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, c.dy - s * 0.02, s * 0.08, s * 0.3), Radius.circular(s * 0.03)),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
    final kernels = [
      Offset(c.dx - s * 0.12, c.dy - s * 0.18),
      Offset(c.dx, c.dy - s * 0.26),
      Offset(c.dx + s * 0.12, c.dy - s * 0.16),
      Offset(c.dx + s * 0.02, c.dy - s * 0.1),
    ];
    for (final k in kernels) {
      canvas.drawCircle(k, s * 0.08, Paint()..color = secondary);
      canvas.drawCircle(k.translate(-s * 0.015, -s * 0.015), s * 0.03, Paint()..color = Colors.white.withValues(alpha: 0.55));
    }
  }

  void _paintCalculator(Canvas canvas, Offset c, double s) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s * 0.52, height: s * 0.64),
      Radius.circular(s * 0.1),
    );
    canvas.drawRRect(body, Paint()..color = accent);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -s * 0.18), width: s * 0.38, height: s * 0.14),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(c.dx - s * 0.12 + col * s * 0.12, c.dy + s * 0.02 + row * s * 0.11),
          s * 0.035,
          Paint()..color = secondary.withValues(alpha: 0.85),
        );
      }
    }
  }

  void _paintPalette(Canvas canvas, Offset c, double s) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 0.62, height: s * 0.5),
      Paint()..color = accent,
    );
    canvas.drawCircle(c.translate(s * 0.16, s * 0.02), s * 0.1, Paint()..color = const Color(0xFFFFF4E8));
    final dots = [
      (c.translate(-s * 0.16, -s * 0.08), const Color(0xFFFF5A8A)),
      (c.translate(-s * 0.02, -s * 0.14), const Color(0xFF4C8DFF)),
      (c.translate(s * 0.12, -s * 0.1), const Color(0xFFFFC857)),
      (c.translate(-s * 0.1, s * 0.1), const Color(0xFF34C38F)),
    ];
    for (final (offset, color) in dots) {
      canvas.drawCircle(offset, s * 0.065, Paint()..color = color);
    }
  }

  void _paintPlane(Canvas canvas, Offset c, double s) {
    final plane = Path()
      ..moveTo(c.dx - s * 0.28, c.dy + s * 0.08)
      ..lineTo(c.dx + s * 0.28, c.dy - s * 0.04)
      ..lineTo(c.dx + s * 0.02, c.dy + s * 0.04)
      ..lineTo(c.dx - s * 0.02, c.dy + s * 0.26)
      ..close();
    canvas.drawPath(plane, Paint()..color = accent);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.02, c.dy + s * 0.02)
        ..lineTo(c.dx + s * 0.18, c.dy - s * 0.16)
        ..lineTo(c.dx + s * 0.08, c.dy + s * 0.04)
        ..close(),
      Paint()..color = secondary,
    );
  }

  void _paintBag(Canvas canvas, Offset c, double s) {
    final bag = Path()
      ..moveTo(c.dx - s * 0.2, c.dy - s * 0.05)
      ..lineTo(c.dx - s * 0.22, c.dy + s * 0.28)
      ..lineTo(c.dx + s * 0.22, c.dy + s * 0.28)
      ..lineTo(c.dx + s * 0.2, c.dy - s * 0.05)
      ..close();
    canvas.drawPath(bag, Paint()..color = accent);
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, -s * 0.08), width: s * 0.32, height: s * 0.28),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c.translate(-s * 0.05, -s * 0.16), s * 0.09, Paint()..color = secondary);
    canvas.drawCircle(c.translate(s * 0.1, -s * 0.12), s * 0.07, Paint()..color = const Color(0xFF57C46B));
  }

  void _paintGlobe(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(c, s * 0.26, Paint()..color = accent);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 0.22, height: s * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035,
    );
    canvas.drawLine(
      c.translate(-s * 0.22, 0),
      c.translate(s * 0.22, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = s * 0.035,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, s * 0.28), width: s * 0.28, height: s * 0.08),
        Radius.circular(s * 0.03),
      ),
      Paint()..color = secondary,
    );
  }

  void _paintIsland(Canvas canvas, Offset c, double s) {
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, s * 0.18), width: s * 0.55, height: s * 0.22),
      Paint()..color = const Color(0xFFFFE0A3),
    );
    canvas.drawCircle(c.translate(s * 0.18, -s * 0.16), s * 0.08, Paint()..color = secondary);
    canvas.drawLine(
      c.translate(0, s * 0.12),
      c.translate(0, -s * 0.08),
      Paint()
        ..color = const Color(0xFF8B5A2B)
        ..strokeWidth = s * 0.045
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - s * 0.08)
        ..quadraticBezierTo(c.dx - s * 0.22, c.dy - s * 0.02, c.dx - s * 0.2, c.dy + s * 0.08)
        ..quadraticBezierTo(c.dx - s * 0.05, c.dy - s * 0.02, c.dx, c.dy - s * 0.08)
        ..quadraticBezierTo(c.dx + s * 0.22, c.dy - s * 0.02, c.dx + s * 0.2, c.dy + s * 0.08)
        ..quadraticBezierTo(c.dx + s * 0.05, c.dy - s * 0.02, c.dx, c.dy - s * 0.08),
      Paint()..color = accent,
    );
  }

  void _paintBike(Canvas canvas, Offset c, double s) {
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(c.translate(-s * 0.16, s * 0.08), s * 0.12, stroke);
    canvas.drawCircle(c.translate(s * 0.18, s * 0.08), s * 0.12, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.16, c.dy + s * 0.08)
        ..lineTo(c.dx - s * 0.02, c.dy - s * 0.08)
        ..lineTo(c.dx + s * 0.14, c.dy + s * 0.08)
        ..moveTo(c.dx - s * 0.02, c.dy - s * 0.08)
        ..lineTo(c.dx + s * 0.08, c.dy - s * 0.2)
        ..lineTo(c.dx + s * 0.2, c.dy - s * 0.2),
      stroke,
    );
    canvas.drawCircle(c.translate(s * 0.08, -s * 0.2), s * 0.035, Paint()..color = secondary);
  }

  void _paintBook(Canvas canvas, Offset c, double s) {
    final left = Path()
      ..moveTo(c.dx, c.dy - s * 0.22)
      ..lineTo(c.dx - s * 0.24, c.dy - s * 0.16)
      ..lineTo(c.dx - s * 0.24, c.dy + s * 0.22)
      ..lineTo(c.dx, c.dy + s * 0.16)
      ..close();
    final right = Path()
      ..moveTo(c.dx, c.dy - s * 0.22)
      ..lineTo(c.dx + s * 0.24, c.dy - s * 0.16)
      ..lineTo(c.dx + s * 0.24, c.dy + s * 0.22)
      ..lineTo(c.dx, c.dy + s * 0.16)
      ..close();
    canvas.drawPath(left, Paint()..color = accent);
    canvas.drawPath(right, Paint()..color = secondary);
    canvas.drawLine(
      c.translate(0, -s * 0.2),
      c.translate(0, s * 0.16),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = s * 0.03,
    );
  }

  void _paintPhone(Canvas canvas, Offset c, double s) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s * 0.36, height: s * 0.58),
      Radius.circular(s * 0.1),
    );
    canvas.drawRRect(body, Paint()..color = accent);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -s * 0.02), width: s * 0.26, height: s * 0.4),
        Radius.circular(s * 0.05),
      ),
      Paint()..color = secondary.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c.translate(0, s * 0.22), s * 0.03, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _CategoryGlyphPainter oldDelegate) =>
      oldDelegate.category != category || oldDelegate.accent != accent || oldDelegate.secondary != secondary;
}

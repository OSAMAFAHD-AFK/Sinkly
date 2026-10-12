import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';

/// Hero illustration: a flat-vector character scrubbing a plate at the sink.
///
/// Drawn entirely with one [CustomPainter] (no assets, a few KB, 60 fps) in the
/// Sinkly palette. [cleanliness] morphs the whole scene:
///   0 → murky water, a tower of dirty plates, buzzing flies, slow scrubbing
///   1 → crystal water, rising soap bubbles, sparkles, a running tap
/// The change is tweened, so flipping the value plays a satisfying
/// "dirty → sparkling" transformation. The scene mirrors itself in RTL.
class WashingCharacterSceneWidget extends StatefulWidget {
  const WashingCharacterSceneWidget({super.key, this.cleanliness = 1, this.width = 300});

  final double cleanliness;
  final double width;

  static const double _designWidth = 320;
  static const double _designHeight = 280;

  @override
  State<WashingCharacterSceneWidget> createState() => _WashingCharacterSceneWidgetState();
}

class _WashingCharacterSceneWidgetState extends State<WashingCharacterSceneWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * WashingCharacterSceneWidget._designHeight / WashingCharacterSceneWidget._designWidth;
    final scene = TweenAnimationBuilder<double>(
      tween: Tween(end: widget.cleanliness.clamp(0, 1)),
      duration: const Duration(milliseconds: 2400),
      curve: Curves.easeInOutCubic,
      builder: (context, cleanliness, _) => RepaintBoundary(
        child: CustomPaint(
          size: Size(widget.width, height),
          painter: _SinkScenePainter(animation: _controller, cleanliness: cleanliness),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: height,
        // The character faces the sink; in RTL the whole scene mirrors.
        child: Transform.flip(flipX: context.isRtl, child: scene),
      ),
    );
  }
}

class _SinkScenePainter extends CustomPainter {
  _SinkScenePainter({required this.animation, required this.cleanliness}) : super(repaint: animation);

  final Animation<double> animation;
  final double cleanliness;

  static const Color _skin = Color(0xFFF8D2B6);
  static const Color _hair = Color(0xFF1F2A4D);
  static const Color _top = Color(0xFFCFC8FF);
  static const Color _pants = Color(0xFF3D4B7A);
  static const Color _wood = Color(0xFFD9A58B);
  static const Color _murky = Color(0xFFCDBBA7);
  static const Color _cabinet = Color(0xFFEDF3F9);
  static const Color _door = Color(0xFFDCE6F0);
  static const Color _gold = Color(0xFFFFC857);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / WashingCharacterSceneWidget._designWidth);
    final t = animation.value;
    final c = cleanliness;
    const tau = 2 * math.pi;
    final bob = math.sin(t * tau * 3) * 1.4;

    _drawGlow(canvas, c);
    _drawShelf(canvas);
    _drawCabinet(canvas);
    _drawFaucet(canvas, t, c);
    _drawBasin(canvas, c);
    _drawPile(canvas, t, c);
    _drawCharacterBody(canvas, t, bob, c);
    _drawScrubbingArm(canvas, t, bob, c);
    _drawBubbles(canvas, t, c);
    _drawSparkles(canvas, t, c);
    _drawFlies(canvas, t, c);
    canvas.restore();
  }

  void _drawGlow(Canvas canvas, double c) {
    final color = Color.lerp(const Color(0xFFFFD9C7), AppColors.primary, c)!;
    canvas.drawCircle(
      const Offset(175, 150),
      150,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: const Offset(175, 150), radius: 150)),
    );
  }

  void _drawShelf(Canvas canvas) {
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD5E2EE);
    for (final x in const [196.0, 236.0, 276.0]) {
      const y = 62.0;
      canvas.drawCircle(Offset(x, y), 25, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 25, rim);
      canvas.drawCircle(Offset(x, y), 16, rim..color = const Color(0xFFE5EEF6));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(172, 90, 142, 8), const Radius.circular(4)),
      Paint()..color = _wood,
    );
  }

  void _drawCabinet(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(96, 204, 224, 76), const Radius.circular(10)),
      Paint()..color = _cabinet,
    );
    for (final x in const [108.0, 212.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 220, 96, 52), const Radius.circular(8)),
        Paint()..color = _door,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 40, 226, 16, 4), const Radius.circular(2)),
        Paint()..color = const Color(0xFFB9C9D8),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(90, 196, 236, 14), const Radius.circular(7)),
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
  }

  void _drawFaucet(Canvas canvas, double t, double c) {
    final pipe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9
      ..color = AppColors.primaryDeep;
    final path = Path()
      ..moveTo(290, 198)
      ..lineTo(290, 150)
      ..quadraticBezierTo(290, 126, 264, 126)
      ..lineTo(256, 126)
      ..lineTo(256, 138);
    canvas.drawPath(path, pipe);
    // Water stream (only when clean enough).
    if (c > 0.35) {
      final alpha = ((c - 0.35) / 0.65).clamp(0, 1);
      canvas.drawLine(
        const Offset(256, 142),
        const Offset(256, 188),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary.withValues(alpha: 0.55 * alpha),
      );
      for (var i = 0; i < 3; i++) {
        final p = (t * 4 + i / 3) % 1.0;
        canvas.drawCircle(Offset(256, 142 + p * 44), 2.6, Paint()..color = Colors.white.withValues(alpha: 0.9 * alpha));
      }
    }
  }

  void _drawBasin(Canvas canvas, double c) {
    final water = Color.lerp(_murky, const Color(0xFFBFE6F7), c)!;
    final rect = RRect.fromRectAndRadius(const Rect.fromLTWH(112, 184, 128, 26), const Radius.circular(10));
    canvas.drawRRect(rect, Paint()..color = water);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    // Soft highlight on the water surface.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(122, 188, 50, 4), const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.3 * c),
    );
  }

  void _drawPile(Canvas canvas, double t, double c) {
    // Dirty plates vanish one by one as cleanliness rises.
    const total = 5;
    final visible = (1 - c) * total;
    for (var i = 0; i < total; i++) {
      final alpha = (visible - i).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final dx = (i.isEven ? -1 : 1) * (3.0 + i);
      final dy = 184 - i * 8.0 - (1 - alpha) * 10;
      final center = Offset(166 + dx, dy);
      final plate = Rect.fromCenter(center: center, width: 58 - i * 2, height: 14);
      canvas
        ..drawOval(plate, Paint()..color = Colors.white.withValues(alpha: alpha))
        ..drawOval(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFFD5E2EE).withValues(alpha: alpha),
        );
      // Food smudges.
      canvas
        ..drawCircle(
          center.translate(-8, 0),
          3,
          Paint()..color = const Color(0xFFB98B5E).withValues(alpha: 0.8 * alpha),
        )
        ..drawCircle(
          center.translate(9, 1),
          2.2,
          Paint()..color = const Color(0xFF9CB36B).withValues(alpha: 0.8 * alpha),
        );
    }
  }

  void _drawCharacterBody(Canvas canvas, double t, double bob, double c) {
    const tau = 2 * math.pi;
    final swing = math.sin(t * tau) * 5 * (0.4 + 0.6 * c);

    // Legs + shoes.
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(48, 214, 18, 62), const Radius.circular(8)),
        Paint()..color = _pants,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(70, 214, 18, 62), const Radius.circular(8)),
        Paint()..color = _pants,
      )
      ..drawOval(const Rect.fromLTWH(44, 270, 26, 10), Paint()..color = _hair)
      ..drawOval(const Rect.fromLTWH(68, 270, 26, 10), Paint()..color = _hair);

    // Ponytail (swaying) + back hair.
    final ponytail = Path()
      ..moveTo(44, 66 + bob)
      ..quadraticBezierTo(14 + swing, 82 + bob, 20 + swing * 1.5, 128 + bob)
      ..quadraticBezierTo(36, 104 + bob, 50, 92 + bob)
      ..close();
    canvas
      ..drawPath(ponytail, Paint()..color = _hair)
      ..drawOval(Rect.fromLTWH(42, 52 + bob, 56, 70), Paint()..color = _hair);

    // Left arm (relaxed).
    canvas
      ..drawLine(
        Offset(48, 136 + bob),
        Offset(42, 190 + bob),
        Paint()
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round
          ..color = _top,
      )
      ..drawCircle(Offset(42, 194 + bob), 7, Paint()..color = _skin);

    // Torso, apron.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(40, 118 + bob, 58, 100), const Radius.circular(22)),
      Paint()..color = _top,
    );
    final apron = Path()
      ..moveTo(52, 134 + bob)
      ..lineTo(86, 134 + bob)
      ..lineTo(95, 218)
      ..lineTo(43, 218)
      ..close();
    canvas
      ..drawPath(apron, Paint()..color = AppColors.primary)
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(57, 176 + bob * 0.4, 24, 18), const Radius.circular(5)),
        Paint()..color = AppColors.primaryDeep.withValues(alpha: 0.55),
      )
      ..drawLine(
        Offset(54, 134 + bob),
        Offset(62, 112 + bob),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      )
      ..drawLine(
        Offset(84, 134 + bob),
        Offset(76, 112 + bob),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );

    // Neck + head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(62, 104 + bob, 16, 20), const Radius.circular(6)),
      Paint()..color = _skin,
    );
    final head = Offset(70, 84 + bob);
    // Tired when dirty: head tilts slightly down.
    canvas
      ..save()
      ..translate(head.dx, head.dy + 20)
      ..rotate(0.08 * (1 - c))
      ..translate(-head.dx, -head.dy - 20)
      ..drawCircle(head, 25, Paint()..color = _skin)
      ..drawCircle(head.translate(15, 8), 5, Paint()..color = const Color(0xFFFF9BB3).withValues(alpha: 0.45));
    final fringe = Path()
      ..moveTo(44, 88 + bob)
      ..cubicTo(38, 46 + bob, 100, 44 + bob, 96, 84 + bob)
      ..cubicTo(88, 66 + bob, 64, 62 + bob, 44, 88 + bob);
    canvas
      ..drawPath(fringe, Paint()..color = _hair)
      ..restore();

    // A tiny smile appears when the kitchen is clean.
    if (c > 0.5) {
      canvas.drawArc(
        Rect.fromCenter(center: head.translate(11, 14), width: 14, height: 9),
        0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2
          ..color = const Color(0xFFD97B66).withValues(alpha: ((c - 0.5) * 2).clamp(0, 1)),
      );
    }
  }

  /// Two-bone IK: the hand follows a scrubbing path, the elbow bends naturally.
  void _drawScrubbingArm(Canvas canvas, double t, double bob, double c) {
    const tau = 2 * math.pi;
    final speed = 2 + 3 * c; // scrubs faster when it's going well
    final phase = t * tau * speed;
    final shoulder = Offset(90, 138 + bob);
    final hand = Offset(150 + math.sin(phase) * 18, 184 + math.sin(phase * 2) * 2);
    const upper = 46.0;
    const lower = 52.0;

    final delta = hand - shoulder;
    final distance = delta.distance.clamp(1.0, upper + lower - 0.5);
    final a = (upper * upper - lower * lower + distance * distance) / (2 * distance);
    final h = math.sqrt(math.max(0, upper * upper - a * a));
    final direction = delta / delta.distance;
    final elbow = shoulder + direction * a + Offset(-direction.dy, direction.dx) * h;

    // Plate + sponge in the hand.
    final plate = Rect.fromCenter(center: hand.translate(8, 4), width: 50, height: 15);
    canvas
      ..drawOval(plate, Paint()..color = Colors.white)
      ..drawOval(
        plate,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = const Color(0xFFD5E2EE),
      );
    canvas
      ..drawLine(
        shoulder,
        elbow,
        Paint()
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = _top,
      )
      ..drawLine(
        elbow,
        hand,
        Paint()
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = _skin,
      )
      ..drawCircle(hand, 8, Paint()..color = _skin)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: hand.translate(-2, 2), width: 18, height: 11),
          const Radius.circular(4),
        ),
        Paint()..color = _gold,
      );
  }

  void _drawBubbles(Canvas canvas, double t, double c) {
    if (c < 0.05) return;
    for (var i = 0; i < 11; i++) {
      final p = (t * 1.3 + i / 11) % 1.0;
      final x = 118 + (i * 41 % 118) + math.sin(p * 6 + i) * 7;
      final y = 184 - p * 120;
      final r = 4.0 + (i % 3) * 3;
      final alpha = math.sin(p * math.pi) * c;
      canvas
        ..drawCircle(Offset(x, y), r, Paint()..color = AppColors.primary.withValues(alpha: 0.22 * alpha))
        ..drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.95 * alpha),
        )
        ..drawCircle(
          Offset(x - r * 0.35, y - r * 0.35),
          r * 0.22,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
    }
  }

  void _drawSparkles(Canvas canvas, double t, double c) {
    if (c < 0.4) return;
    final alpha = ((c - 0.4) / 0.6).clamp(0.0, 1.0);
    const spots = [Offset(214, 30), Offset(304, 56), Offset(160, 96), Offset(268, 18), Offset(124, 150)];
    for (var i = 0; i < spots.length; i++) {
      final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2 + i * 1.3);
      final radius = (5 + 6 * pulse) * (i == 2 || i == 4 ? 0.8 : 1);
      canvas.drawPath(
        _star(spots[i], radius),
        Paint()..color = (i.isEven ? _gold : Colors.white).withValues(alpha: alpha * (0.5 + 0.5 * pulse)),
      );
      canvas.drawPath(
        _star(spots[i], radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.primary.withValues(alpha: alpha * 0.6),
      );
    }
  }

  void _drawFlies(Canvas canvas, double t, double c) {
    final alpha = (1 - c * 2).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    for (var i = 0; i < 3; i++) {
      final a = t * 2 * math.pi * (2 + i) + i * 2.1;
      final center = Offset(168 + math.cos(a) * (18 + i * 6), 138 + math.sin(a * 1.3) * (10 + i * 3));
      canvas
        ..drawCircle(center, 2.4, Paint()..color = _hair.withValues(alpha: alpha))
        ..drawOval(
          Rect.fromCenter(center: center.translate(-2, -2.5), width: 5, height: 3),
          Paint()..color = Colors.white.withValues(alpha: 0.8 * alpha),
        );
    }
  }

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.28;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _SinkScenePainter oldDelegate) => oldDelegate.cleanliness != cleanliness;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';

/// Screen 4 hero — "what a clean kitchen feels like", told as a transformation:
/// murky water, a dirty pile and a sad face… then the dishes vanish into a
/// shining rack, soap foam rises, light rays bloom behind her and she beams.
class KitchenTransformationSceneWidget extends StatefulWidget {
  const KitchenTransformationSceneWidget({super.key, this.revealDelay = const Duration(milliseconds: 1300)});

  final Duration revealDelay;

  @override
  State<KitchenTransformationSceneWidget> createState() => _KitchenTransformationSceneWidgetState();
}

class _KitchenTransformationSceneWidgetState extends State<KitchenTransformationSceneWidget>
    with SingleTickerProviderStateMixin {
  static const double _sceneWidth = 320;
  static const double _sceneHeight = 204;
  static const double _characterWidth = 170;

  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 8))
    ..repeat();
  bool _clean = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.revealDelay, () {
      if (!mounted) return;
      AppFunctions.mediumHaptic();
      setState(() => _clean = true);
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = TweenAnimationBuilder<double>(
      tween: Tween(end: _clean ? 1 : 0),
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeInOutCubic,
      builder: (context, cleanliness, _) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _KitchenBackdropPainter(animation: _loop, cleanliness: cleanliness),
            ),
          ),
          Positioned(
            left: (_sceneWidth - _characterWidth) / 2,
            top: 0,
            // The character mirrors itself in RTL; the scene around it is
            // mirrored by the outer Transform, so keep her un-flipped here.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: HeroineCharacterWidget(
                width: _characterWidth,
                pose: cleanliness > 0.55 ? HeroinePose.washJoy : HeroinePose.washSad,
                motion: HeroineMotion.scrub,
                prop: HeroineProp.plate,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _KitchenForegroundPainter(animation: _loop, cleanliness: cleanliness),
            ),
          ),
        ],
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: _sceneWidth,
        height: _sceneHeight,
        child: Transform.flip(
          flipX: context.isRtl,
          child: RepaintBoundary(child: scene),
        ),
      ),
    );
  }
}

/// Wall, plate rack and the light rays that bloom when it's clean.
class _KitchenBackdropPainter extends CustomPainter {
  _KitchenBackdropPainter({required this.animation, required this.cleanliness}) : super(repaint: animation);

  final Animation<double> animation;
  final double cleanliness;

  @override
  void paint(Canvas canvas, Size size) {
    final c = cleanliness;
    final t = animation.value;
    const center = Offset(160, 96);

    // Warm, dull halo when dirty → bright sky halo when clean.
    final halo = Color.lerp(const Color(0xFFF2D9CB), AppColors.primary, c)!;
    canvas.drawCircle(
      center,
      150,
      Paint()
        ..shader = RadialGradient(colors: [halo.withValues(alpha: 0.45), halo.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: 150)),
    );

    // Rotating light rays.
    if (c > 0.05) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(t * 2 * math.pi * 0.25);
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final ray = Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(angle - 0.08) * 170, math.sin(angle - 0.08) * 170)
          ..lineTo(math.cos(angle + 0.08) * 170, math.sin(angle + 0.08) * 170)
          ..close();
        canvas.drawPath(
          ray,
          Paint()
            ..shader = RadialGradient(
              colors: [
                (i.isEven ? const Color(0xFFFFE4A3) : Colors.white).withValues(alpha: 0.55 * c),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 170)),
        );
      }
      canvas.restore();
    }

    // Wall plate rack: clean plates pop in one by one.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 70, 74, 7), const Radius.circular(4)),
      Paint()..color = const Color(0xFFD9A58B),
    );
    for (var i = 0; i < 3; i++) {
      final appear = ((c - 0.35 - i * 0.15) / 0.3).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final pop = Curves.elasticOut.transform(appear);
      final plateCenter = Offset(28.0 + i * 23, 52);
      canvas
        ..drawCircle(plateCenter, 15 * pop, Paint()..color = Colors.white)
        ..drawCircle(
          plateCenter,
          15 * pop,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = AppColors.primary.withValues(alpha: 0.7),
        )
        ..drawCircle(
          plateCenter,
          9 * pop,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFDDE8F2),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _KitchenBackdropPainter oldDelegate) => oldDelegate.cleanliness != cleanliness;
}

/// Counter, sink, dirty pile vs. clean stack, foam and sparkles (in front of her).
class _KitchenForegroundPainter extends CustomPainter {
  _KitchenForegroundPainter({required this.animation, required this.cleanliness}) : super(repaint: animation);

  final Animation<double> animation;
  final double cleanliness;

  static const double _counterTop = 140;
  static const Color _gold = Color(0xFFFFC857);

  @override
  void paint(Canvas canvas, Size size) {
    final c = cleanliness;
    final t = animation.value;

    _drawCounter(canvas, size);
    _drawSink(canvas, c);
    _drawFaucet(canvas, t, c);
    _drawDirtyPile(canvas, c);
    _drawCleanStack(canvas, t, c);
    _drawFoam(canvas, t, c);
    _drawSparkles(canvas, t, c);
  }

  void _drawCounter(Canvas canvas, Size size) {
    final counter = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, _counterTop, 304, size.height - _counterTop),
      const Radius.circular(16),
    );
    canvas
      ..drawRRect(counter, Paint()..color = const Color(0xFFF3F7FB))
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(8, _counterTop, 304, 12), const Radius.circular(8)),
        Paint()..color = Colors.white,
      );
    final door = Paint()..color = const Color(0xFFE3EBF3);
    for (final x in const [24.0, 166.0]) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, _counterTop + 24, 130, size.height - _counterTop - 32),
            const Radius.circular(10),
          ),
          door,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 55, _counterTop + 32, 20, 4), const Radius.circular(2)),
          Paint()..color = const Color(0xFFBCCBDA),
        );
    }
  }

  void _drawSink(Canvas canvas, double c) {
    final water = Color.lerp(const Color(0xFFCDBBA7), const Color(0xFFBFE6F7), c)!;
    final basin = RRect.fromRectAndRadius(const Rect.fromLTWH(98, _counterTop - 6, 124, 20), const Radius.circular(10));
    canvas
      ..drawRRect(basin, Paint()..color = water)
      ..drawRRect(
        basin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(108, _counterTop - 2, 44, 3), const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.3 + 0.4 * c),
      );
  }

  void _drawFaucet(Canvas canvas, double t, double c) {
    final pipe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = AppColors.primaryDeep;
    canvas.drawPath(
      Path()
        ..moveTo(206, _counterTop - 4)
        ..lineTo(206, _counterTop - 26)
        ..quadraticBezierTo(206, _counterTop - 38, 194, _counterTop - 38)
        ..lineTo(188, _counterTop - 38)
        ..lineTo(188, _counterTop - 32),
      pipe,
    );
    if (c > 0.3) {
      final alpha = ((c - 0.3) / 0.7).clamp(0.0, 1.0);
      canvas.drawLine(
        const Offset(188, _counterTop - 29),
        const Offset(188, _counterTop - 4),
        Paint()
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary.withValues(alpha: 0.6 * alpha),
      );
      for (var i = 0; i < 3; i++) {
        final p = (t * 12 + i / 3) % 1.0;
        canvas.drawCircle(
          Offset(188, _counterTop - 29 + p * 24),
          2,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }
  }

  void _drawDirtyPile(Canvas canvas, double c) {
    // Plates fly up and fade away as the kitchen gets clean.
    for (var i = 0; i < 4; i++) {
      final leave = ((c - i * 0.12) / 0.45).clamp(0.0, 1.0);
      final alpha = 1 - leave;
      if (alpha <= 0) continue;
      final center = Offset(266 + (i.isEven ? -3.0 : 3.0), _counterTop - 4 - i * 9 - leave * 40);
      final plate = Rect.fromCenter(center: center, width: 66 - i * 3, height: 14);
      canvas
        ..drawOval(plate, Paint()..color = Colors.white.withValues(alpha: alpha))
        ..drawOval(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFFD5E2EE).withValues(alpha: alpha),
        )
        ..drawCircle(
          center.translate(-10, 0),
          3,
          Paint()..color = const Color(0xFFB98B5E).withValues(alpha: 0.85 * alpha),
        )
        ..drawCircle(
          center.translate(9, 1),
          2.4,
          Paint()..color = const Color(0xFF9CB36B).withValues(alpha: 0.85 * alpha),
        );
    }
    // Stink lines while dirty.
    if (c < 0.5) {
      final alpha = (1 - c * 2).clamp(0.0, 1.0);
      final stink = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9CB36B).withValues(alpha: 0.7 * alpha);
      for (var i = 0; i < 3; i++) {
        final x = 254.0 + i * 12;
        final wobble = math.sin(animation.value * 2 * math.pi * 3 + i) * 3;
        canvas.drawPath(
          Path()
            ..moveTo(x, _counterTop - 44)
            ..quadraticBezierTo(x + 6 + wobble, _counterTop - 54, x, _counterTop - 64)
            ..quadraticBezierTo(x - 6 - wobble, _counterTop - 74, x, _counterTop - 84),
          stink,
        );
      }
    }
  }

  void _drawCleanStack(Canvas canvas, double t, double c) {
    for (var i = 0; i < 4; i++) {
      final appear = ((c - 0.3 - i * 0.12) / 0.3).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final drop = (1 - Curves.bounceOut.transform(appear)) * 30;
      final center = Offset(54, _counterTop - 4 - i * 8 - drop);
      final plate = Rect.fromCenter(center: center, width: 62, height: 13);
      canvas
        ..drawOval(plate, Paint()..color = Colors.white)
        ..drawOval(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = AppColors.primary.withValues(alpha: 0.8),
        );
    }
  }

  void _drawFoam(Canvas canvas, double t, double c) {
    if (c < 0.05) return;
    for (var i = 0; i < 14; i++) {
      final p = (t * 3 + i / 14) % 1.0;
      final x = 110 + (i * 53 % 100) + math.sin(p * 7 + i) * 6;
      final y = _counterTop - 4 - p * 120;
      final r = 3.5 + (i % 4) * 2.2;
      final alpha = math.sin(p * math.pi) * c;
      canvas
        ..drawCircle(Offset(x, y), r, Paint()..color = AppColors.primary.withValues(alpha: 0.18 * alpha))
        ..drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = Colors.white.withValues(alpha: 0.95 * alpha),
        )
        ..drawCircle(
          Offset(x - r * 0.35, y - r * 0.35),
          r * 0.22,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
    }
    // Foam crown on the water.
    for (var i = 0; i < 7; i++) {
      final x = 108.0 + i * 17;
      final bob = math.sin(t * 2 * math.pi * 2 + i) * 1.5;
      canvas.drawCircle(
        Offset(x, _counterTop - 6 + bob),
        7 + (i % 2) * 2.0,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * c),
      );
    }
  }

  void _drawSparkles(Canvas canvas, double t, double c) {
    if (c < 0.45) return;
    final alpha = ((c - 0.45) / 0.55).clamp(0.0, 1.0);
    const spots = [Offset(40, 26), Offset(98, 40), Offset(280, 30), Offset(250, 96), Offset(36, 104), Offset(300, 120)];
    for (var i = 0; i < spots.length; i++) {
      final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + i * 1.4);
      final radius = (5 + 7 * pulse) * (i.isOdd ? 0.8 : 1);
      canvas.drawPath(
        _star(spots[i], radius),
        Paint()..color = (i.isEven ? _gold : Colors.white).withValues(alpha: alpha * (0.4 + 0.6 * pulse)),
      );
      canvas.drawPath(
        _star(spots[i], radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.primary.withValues(alpha: alpha * 0.5),
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
  bool shouldRepaint(covariant _KitchenForegroundPainter oldDelegate) => oldDelegate.cleanliness != cleanliness;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Calm mesh gradient painted behind every screen (optionally drifting).
///
/// Animation is opt-in: a moving backdrop forces every glass blur above it to
/// re-render each frame, so only hero flows (splash, onboarding, unlock) use it.
///
/// Implemented with a single [CustomPainter] of soft radial blobs (no blur
/// filters) inside a [RepaintBoundary], so it costs almost nothing per frame.
class MeshGradientBackgroundWidget extends StatefulWidget {
  const MeshGradientBackgroundWidget({super.key, this.palette = MeshPalette.sky, this.animate = false});

  final MeshPalette palette;
  final bool animate;

  @override
  State<MeshGradientBackgroundWidget> createState() => _MeshGradientBackgroundWidgetState();
}

/// Ready-made blob palettes so screens can set a subtle mood.
enum MeshPalette {
  sky([AppColors.meshSky, AppColors.meshLavender, AppColors.meshMint, AppColors.meshSky]),
  warm([AppColors.meshPeach, AppColors.meshSky, AppColors.meshLavender, AppColors.meshPeach]),
  fresh([AppColors.meshMint, AppColors.meshSky, AppColors.meshMint, AppColors.meshLavender]),
  calm([AppColors.meshLavender, AppColors.meshSky, AppColors.meshPeach, AppColors.meshSky]);

  const MeshPalette(this.colors);
  final List<Color> colors;
}

class _MeshGradientBackgroundWidgetState extends State<MeshGradientBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MeshGradientBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshPainter(animation: _controller, colors: widget.palette.colors),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.animation, required this.colors}) : super(repaint: animation);

  final Animation<double> animation;
  final List<Color> colors;

  // Base anchor points (fractions of the screen) for each blob.
  static const List<Offset> _anchors = [Offset(0.1, 0.08), Offset(0.95, 0.28), Offset(0.05, 0.72), Offset(0.85, 0.95)];
  static const List<double> _radiusFactors = [0.75, 0.65, 0.7, 0.8];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final t = animation.value * 2 * math.pi;
    final shortest = size.shortestSide;

    for (var i = 0; i < _anchors.length; i++) {
      final phase = i * math.pi / 2;
      final center = Offset(
        size.width * (_anchors[i].dx + 0.06 * math.sin(t + phase)),
        size.height * (_anchors[i].dy + 0.04 * math.cos(t * 0.8 + phase)),
      );
      final radius = shortest * _radiusFactors[i];
      final color = colors[i % colors.length];
      final paint = Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => oldDelegate.colors != colors;
}

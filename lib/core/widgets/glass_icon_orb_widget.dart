import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/style.dart';

/// A glowing frosted orb holding an icon or emoji — the main illustration
/// primitive of Sinkly (inspired by the AI-orb in the reference designs).
class GlassIconOrbWidget extends StatelessWidget {
  const GlassIconOrbWidget({
    super.key,
    this.icon,
    this.emoji,
    this.size = 120,
    this.glowColor = AppColors.primary,
    this.iconColor = AppColors.primaryInk,
    this.floating = true,
  }) : assert(icon != null || emoji != null);

  final IconData? icon;
  final String? emoji;
  final double size;
  final Color glowColor;
  final Color iconColor;

  /// Gentle up/down bob animation.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final orb = SizedBox.square(
      dimension: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo.
          Container(
            width: size * 1.45,
            height: size * 1.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [glowColor.withValues(alpha: 0.35), glowColor.withValues(alpha: 0)]),
            ),
          ),
          // Glass sphere.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color.lerp(Colors.white, glowColor, 0.25)!],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: -6,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: emoji != null
                ? Text(emoji!, style: TextStyle(fontSize: size * 0.42))
                : Icon(icon, size: size * 0.42, color: iconColor),
          ),
          // Specular highlight.
          PositionedDirectional(
            top: size * 0.32,
            start: size * 0.42,
            child: Container(
              width: size * 0.22,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );

    if (!floating) return orb;
    return RepaintBoundary(
      child: orb
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -5, end: 5, duration: 2600.ms, curve: Curves.easeInOut),
    );
  }
}

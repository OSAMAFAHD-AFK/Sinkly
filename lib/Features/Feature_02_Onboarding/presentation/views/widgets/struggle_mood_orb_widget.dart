import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';

/// Screen 6 hero: a feelings orb that reacts to the selected struggle with a
/// new face, a new glow color and three small icons orbiting around it.
class StruggleMoodOrbWidget extends StatefulWidget {
  const StruggleMoodOrbWidget({super.key, required this.selectedId});

  final String? selectedId;

  @override
  State<StruggleMoodOrbWidget> createState() => _StruggleMoodOrbWidgetState();
}

class _StruggleMoodOrbWidgetState extends State<StruggleMoodOrbWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 7))
    ..repeat();

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  ({String face, Color glow, List<String> satellites}) get _mood => switch (widget.selectedId) {
    'boredom' => (face: '🥱', glow: AppColors.meshLavender, satellites: ['💤', '⏳', '☁️']),
    'adhd_paralysis' => (face: '🌀', glow: AppColors.primary, satellites: ['💭', '⚡', '❓']),
    'social_media' => (face: '📱', glow: const Color(0xFFFFB7A8), satellites: ['❤️', '💬', '🔔']),
    _ => (face: '🤔', glow: AppColors.primary, satellites: ['✨', '💡', '💭']),
  };

  @override
  Widget build(BuildContext context) {
    final mood = _mood;
    return SizedBox(
      width: 200,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: AppDurations.slow,
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [mood.glow.withValues(alpha: 0.45), mood.glow.withValues(alpha: 0)]),
            ),
          ),
          // Orbiting satellites.
          AnimatedBuilder(
            animation: _orbit,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < mood.satellites.length; i++)
                  Transform.translate(
                    offset: Offset(
                      math.cos(_orbit.value * 2 * math.pi + i * 2.094) * 76,
                      math.sin(_orbit.value * 2 * math.pi + i * 2.094) * 54,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      child: Text(
                        mood.satellites[i],
                        key: ValueKey('${widget.selectedId}$i'),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // The orb.
          AnimatedContainer(
                duration: AppDurations.slow,
                curve: Curves.easeOutCubic,
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color.lerp(Colors.white, mood.glow, 0.35)!],
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: mood.glow.withValues(alpha: 0.5),
                      blurRadius: 36,
                      spreadRadius: -6,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  switchInCurve: Curves.elasticOut,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: RotationTransition(turns: Tween(begin: -0.1, end: 0.0).animate(animation), child: child),
                  ),
                  child: Text(mood.face, key: ValueKey(mood.face), style: const TextStyle(fontSize: 46)),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 1800.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

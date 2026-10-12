import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Emojis that pop, drift upward with a little sideways sway and fade —
/// used for likes escaping a phone, "Z z z" while yawning, sparkles of joy…
class RisingEmojiParticlesWidget extends StatelessWidget {
  const RisingEmojiParticlesWidget({
    super.key,
    required this.emojis,
    this.rise = 86,
    this.spread = 18,
    this.fontSize = 15,
    this.interval = const Duration(milliseconds: 380),
    this.lifetime = const Duration(milliseconds: 1900),
  });

  final List<String> emojis;
  final double rise;
  final double spread;
  final double fontSize;
  final Duration interval;
  final Duration lifetime;

  @override
  Widget build(BuildContext context) {
    final lifeMs = lifetime.inMilliseconds;
    return IgnorePointer(
      child: SizedBox(
        width: 60,
        height: 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < emojis.length; i++)
              Positioned(
                left: 18 + math.sin(i * 1.7) * 14,
                top: 0,
                child: Text(emojis[i], style: TextStyle(fontSize: fontSize))
                    .animate(onPlay: (c) => c.repeat(), delay: (i * interval.inMilliseconds).ms)
                    .fadeIn(duration: 200.ms)
                    .moveY(begin: 0, end: -rise, duration: lifeMs.ms, curve: Curves.easeOut)
                    .moveX(begin: 0, end: (i.isEven ? -1 : 1) * spread, duration: lifeMs.ms)
                    .scaleXY(begin: 0.4, end: 1.15, duration: 600.ms, curve: Curves.easeOutBack)
                    .then(delay: (lifeMs - 1000).ms)
                    .fadeOut(duration: 400.ms),
              ),
          ],
        ),
      ),
    );
  }
}

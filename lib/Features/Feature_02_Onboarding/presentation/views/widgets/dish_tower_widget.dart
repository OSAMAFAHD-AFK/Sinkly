import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';

/// Screen 5 hero: a wobbling tower of dirty plates that GROWS with the answer
/// the user picks (1 = a day, 2 = several days, 3 = disaster). Each plate
/// drops in with a springy bounce, so every tap gives instant visual feedback.
class DishTowerWidget extends StatelessWidget {
  const DishTowerWidget({super.key, required this.level});

  /// 0 = nothing selected yet (small default pile), 1…3 = severity.
  final int level;

  int get _plateCount => switch (level) {
    1 => 4,
    2 => 8,
    3 => 13,
    _ => 3,
  };

  @override
  Widget build(BuildContext context) {
    final count = _plateCount;
    final isDisaster = level == 3;
    return SizedBox(
      width: 190, // heroine (128) + gap + tower must fit the 330-wide scene
      height: 200,
      child:
          Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Counter shadow.
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(70),
                      ),
                    ),
                  ),
                  for (var i = 0; i < count; i++)
                    Positioned(
                      bottom: 10 + i * 12.0,
                      child: _Plate(index: i, tilt: isDisaster ? 1.6 : 1),
                    ),
                  if (level >= 2) const Positioned(top: 4, right: 18, child: _Fly(delayMs: 0)),
                  if (isDisaster) ...const [
                    Positioned(top: 22, left: 14, child: _Fly(delayMs: 400)),
                    Positioned(top: 0, left: 80, child: _Fly(delayMs: 800)),
                  ],
                ],
              )
              // The taller the tower, the more nervous it wobbles.
              .animate(key: ValueKey(level), onPlay: (c) => c.repeat(reverse: true))
              .rotate(
                begin: -0.004 * level,
                end: 0.004 * level,
                duration: (900 - level * 150).ms,
                curve: Curves.easeInOut,
              ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.index, required this.tilt});

  final int index;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index * 13 + 5);
    final dx = (random.nextDouble() - 0.5) * 16 * tilt;
    final width = 118.0 - (index % 3) * 6;
    final smudgeColor = const [Color(0xFFB98B5E), Color(0xFF9CB36B), Color(0xFFD98C6C)][index % 3];

    return Transform.translate(
      offset: Offset(dx, 0),
      child:
          Container(
                width: width,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD5E2EE), width: 2),
                  boxShadow: AppShadows.soft,
                ),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 14 + random.nextDouble() * 40,
                      top: 6,
                      child: Container(
                        width: 10 + random.nextDouble() * 8,
                        height: 7,
                        decoration: BoxDecoration(
                          color: smudgeColor.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate(key: ValueKey('plate$index'), delay: (index * 55).ms)
              .moveY(begin: -120, end: 0, duration: 520.ms, curve: Curves.bounceOut)
              .fadeIn(duration: 150.ms),
    );
  }
}

class _Fly extends StatelessWidget {
  const _Fly({required this.delayMs});

  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return const Text('🪰', style: TextStyle(fontSize: 18))
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
        .move(begin: const Offset(-10, 4), end: const Offset(12, -8), duration: 700.ms, curve: Curves.easeInOut)
        .rotate(begin: -0.1, end: 0.1, duration: 350.ms);
  }
}

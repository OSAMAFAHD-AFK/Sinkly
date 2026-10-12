import 'package:flutter/material.dart';

import 'dish_tower_widget.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';

/// Screen 5 hero: the heroine stands next to the dish tower and REACTS to the
/// answer — calm → "meh" → worried with a sweat drop → hands-on-head panic as
/// the tower grows. Users see their own feeling acted out, instantly.
class DishOverwhelmReactionSceneWidget extends StatelessWidget {
  const DishOverwhelmReactionSceneWidget({super.key, required this.level});

  /// 0 = nothing selected yet, 1…3 = severity.
  final int level;

  @override
  Widget build(BuildContext context) {
    final (pose, motion) = switch (level) {
      1 => (HeroinePose.meh, HeroineMotion.idle),
      2 => (HeroinePose.worried, HeroineMotion.idle),
      3 => (HeroinePose.overwhelmed, HeroineMotion.stress),
      _ => (HeroinePose.curious, HeroineMotion.idle),
    };

    return SizedBox(
      width: 330,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          HeroineCharacterWidget(width: 128, pose: pose, motion: motion),
          const SizedBox(width: 4),
          DishTowerWidget(level: level),
        ],
      ),
    );
  }
}

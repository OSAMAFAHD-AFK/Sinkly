import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'rising_emoji_particles_widget.dart';

/// Screen 6 hero: the heroine ACTS OUT the struggle the user picks —
///  • Boredom        → sleepy eyes, a huge yawn, floating "Z z z".
///  • ADHD paralysis → hands on her head while thoughts whirl around her.
///  • Social media   → glued to her phone while likes float away.
/// Nothing selected yet → she tilts her head, curious, with a "?" bubble.
class StruggleReactionSceneWidget extends StatelessWidget {
  const StruggleReactionSceneWidget({super.key, required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    const characterWidth = 142.0;
    final height = HeroineCharacterWidget.heightFor(characterWidth);

    final (pose, motion, prop) = switch (selectedId) {
      'boredom' => (HeroinePose.sleepy, HeroineMotion.yawn, HeroineProp.none),
      'adhd_paralysis' => (HeroinePose.overwhelmed, HeroineMotion.stress, HeroineProp.none),
      'social_media' => (HeroinePose.scroll, HeroineMotion.scroll, HeroineProp.phone),
      _ => (HeroinePose.curious, HeroineMotion.idle, HeroineProp.none),
    };

    final Widget effect = switch (selectedId) {
      'boredom' => const PositionedDirectional(
        end: 92,
        top: 34,
        child: RisingEmojiParticlesWidget(
          emojis: ['💤', 'z', 'Z'],
          rise: 60,
          spread: 22,
          fontSize: 18,
          interval: Duration(milliseconds: 650),
        ),
      ),
      'adhd_paralysis' => Positioned(
        top: 4,
        left: 0,
        right: 0,
        child: Center(child: _WhirlingThoughts(key: ValueKey(selectedId))),
      ),
      'social_media' => PositionedDirectional(
        end: 128,
        top: height * 0.38,
        child: const RisingEmojiParticlesWidget(emojis: ['❤️', '👍', '🔔', '❤️', '💬']),
      ),
      _ => PositionedDirectional(
        end: 90,
        top: 10,
        child:
            Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.floating,
                  ),
                  child: Text('?', style: AppTextStyles.title.copyWith(color: AppColors.primaryInk)),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 1200.ms, curve: Curves.easeInOut),
      ),
    };

    return SizedBox(
      width: 320,
      height: height + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_haloFor(selectedId).withValues(alpha: 0.55), _haloFor(selectedId).withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          HeroineCharacterWidget(width: characterWidth, pose: pose, motion: motion, prop: prop),
          // Effect layer cross-fades whenever the answer changes.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Stack(key: ValueKey(selectedId), clipBehavior: Clip.none, children: [effect]),
            ),
          ),
        ],
      ),
    );
  }

  static Color _haloFor(String? id) => switch (id) {
    'boredom' => AppColors.meshLavender,
    'adhd_paralysis' => const Color(0xFFFFD7C2),
    'social_media' => const Color(0xFFFFC7D6),
    _ => AppColors.primary,
  };
}

/// Thought fragments orbiting her head, at different speeds and depths.
class _WhirlingThoughts extends StatefulWidget {
  const _WhirlingThoughts({super.key});

  @override
  State<_WhirlingThoughts> createState() => _WhirlingThoughtsState();
}

class _WhirlingThoughtsState extends State<_WhirlingThoughts> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();
  static const _thoughts = ['💭', '⚡', '❓', '📋', '🌀'];

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 90,
      child: AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) {
          final items = <({double depth, Widget child})>[];
          for (var i = 0; i < _thoughts.length; i++) {
            final angle = _orbit.value * 2 * math.pi * (i.isEven ? 1 : -1) + i * 2 * math.pi / _thoughts.length;
            final depth = (math.sin(angle) + 1) / 2;
            items.add((
              depth: depth,
              child: Transform.translate(
                offset: Offset(math.cos(angle) * 70, math.sin(angle) * 22 + 6),
                child: Opacity(
                  opacity: 0.45 + 0.55 * depth,
                  child: Transform.scale(
                    scale: 0.75 + 0.45 * depth,
                    child: Text(_thoughts[i], style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ));
          }
          items.sort((a, b) => a.depth.compareTo(b.depth));
          return Stack(alignment: Alignment.center, children: [for (final item in items) item.child]);
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.6, curve: Curves.easeOutBack);
  }
}

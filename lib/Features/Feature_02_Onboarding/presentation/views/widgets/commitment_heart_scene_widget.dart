import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'rising_emoji_particles_widget.dart';

/// Screen 12 hero: the heroine holds a heart to her chest. While the user
/// presses "hold to commit", the heart GROWS and glows in sync with their
/// finger; when the commitment is sealed she lights up with joy and hearts
/// float away. The gesture and the emotion become one moment.
class CommitmentHeartSceneWidget extends StatefulWidget {
  const CommitmentHeartSceneWidget({super.key, required this.holdProgress, required this.committed});

  final ValueListenable<double> holdProgress;
  final bool committed;

  @override
  State<CommitmentHeartSceneWidget> createState() => _CommitmentHeartSceneWidgetState();
}

class _CommitmentHeartSceneWidgetState extends State<CommitmentHeartSceneWidget> {
  final ValueNotifier<double> _heartScale = ValueNotifier(0.8);

  @override
  void initState() {
    super.initState();
    widget.holdProgress.addListener(_sync);
    _sync();
  }

  void _sync() => _heartScale.value = widget.committed ? 1.5 : 0.8 + widget.holdProgress.value * 0.75;

  @override
  void didUpdateWidget(covariant CommitmentHeartSceneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdProgress != widget.holdProgress) {
      oldWidget.holdProgress.removeListener(_sync);
      widget.holdProgress.addListener(_sync);
    }
    _sync();
  }

  @override
  void dispose() {
    widget.holdProgress.removeListener(_sync);
    _heartScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const characterWidth = 150.0;
    final height = HeroineCharacterWidget.heightFor(characterWidth);

    return SizedBox(
      width: 300,
      height: height + 6,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Halo that warms up with the hold progress.
          Positioned(
            bottom: 8,
            child: ValueListenableBuilder<double>(
              valueListenable: widget.holdProgress,
              builder: (context, progress, _) {
                final glow = widget.committed ? 1.0 : progress;
                final color = Color.lerp(AppColors.primary, const Color(0xFFFFA8C5), glow)!;
                return Container(
                  width: 180 + glow * 50,
                  height: 180 + glow * 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.45 + glow * 0.25),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          HeroineCharacterWidget(
            width: characterWidth,
            pose: widget.committed ? HeroinePose.cherishJoy : HeroinePose.cherish,
            motion: widget.committed ? HeroineMotion.cheer : HeroineMotion.cherish,
            prop: HeroineProp.heart,
            propScale: _heartScale,
          ),
          if (widget.committed)
            Positioned(
              top: height * 0.32,
              child: const RisingEmojiParticlesWidget(
                emojis: ['💖', '✨', '💙', '💖', '✨', '💙'],
                rise: 120,
                spread: 46,
                fontSize: 20,
                interval: Duration(milliseconds: 160),
              ),
            ),
        ],
      ),
    );
  }
}

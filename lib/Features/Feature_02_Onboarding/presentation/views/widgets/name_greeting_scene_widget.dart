import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';

/// Screen 2 hero: the heroine waves hello. As soon as the user types, her
/// speech bubble greets them BY NAME and she lights up with joy — the first
/// emotional "she sees me" moment of the funnel.
class NameGreetingSceneWidget extends StatelessWidget {
  const NameGreetingSceneWidget({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hasName = name.trim().isNotEmpty;
    const characterWidth = 150.0;

    return SizedBox(
      width: 320,
      height: HeroineCharacterWidget.heightFor(characterWidth) + 6,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Soft halo behind her.
          Positioned(
            bottom: 10,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (hasName ? AppColors.primary : AppColors.meshLavender).withValues(alpha: 0.5),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 34,
            bottom: 0,
            child: HeroineCharacterWidget(
              width: characterWidth,
              pose: hasName ? HeroinePose.waveJoy : HeroinePose.wave,
              motion: HeroineMotion.wave,
            ),
          ),
          PositionedDirectional(
            end: 6,
            top: 18,
            child: _SpeechBubble(
              key: ValueKey(hasName),
              text: hasName ? context.tr('scene_hi_name', {'name': name.trim()}) : context.tr('scene_hi_there'),
              highlight: hasName,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.text, required this.highlight});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: highlight ? AppGradients.primaryButton : null,
              color: highlight ? null : Colors.white,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                topEnd: Radius.circular(20),
                bottomEnd: Radius.circular(20),
                bottomStart: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: highlight ? AppShadows.primaryGlow(strength: 0.6) : AppShadows.floating,
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 14,
                color: highlight ? AppColors.onPrimary : AppColors.ink,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .scaleXY(
          begin: 0.6,
          end: 1,
          duration: 520.ms,
          curve: Curves.elasticOut,
          alignment: AlignmentDirectional.bottomStart.resolve(Directionality.of(context)),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

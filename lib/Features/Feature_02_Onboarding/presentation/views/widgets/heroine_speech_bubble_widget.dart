import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';

/// The heroine's speech bubble: its tail (bottom-start corner) points back
/// at her, and it floats gently. [highlight] = happy sky-gradient style,
/// otherwise a calm white bubble (e.g. while she is sad).
class HeroineSpeechBubbleWidget extends StatelessWidget {
  const HeroineSpeechBubbleWidget({super.key, required this.text, this.highlight = true, this.maxWidth = 170});

  final String text;
  final bool highlight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
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
                fontSize: 13.5,
                height: 1.3,
                color: highlight ? AppColors.onPrimary : AppColors.ink,
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

/// Pops a new bubble in (springy) whenever [text] changes.
class HeroineSpeechBubbleSwitcherWidget extends StatelessWidget {
  const HeroineSpeechBubbleSwitcherWidget({super.key, required this.text, this.highlight = true, this.maxWidth = 170});

  final String text;
  final bool highlight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.elasticOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        alignment: AlignmentDirectional.bottomStart.resolve(Directionality.of(context)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: HeroineSpeechBubbleWidget(
        key: ValueKey('$text|$highlight'),
        text: text,
        highlight: highlight,
        maxWidth: maxWidth,
      ),
    );
  }
}

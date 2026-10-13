import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_speech_bubble_widget.dart';
import '../../../data/models/user_feedback_model.dart';
import '../../manager/feedback_cubit.dart';

/// The message card with the heroine peeking over its top edge, hands
/// resting on it like on a desk. She reacts to everything the user does:
///  • category picked → her own greeting + a floating emoji (💡 🎨 🔍 🔒)
///  • typing          → she leans in and reads along ("I'm reading…")
///  • a real idea     → she lights up ("Love it!")
///  • sending         → she hugs a heart while it flies to the team.
class FeedbackComposerWidget extends StatelessWidget {
  const FeedbackComposerWidget({super.key, required this.controller});

  final TextEditingController controller;

  /// Matches the cubit/repo minimum length for a valid suggestion.
  static const int _meaningfulLength = 10;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeedbackCubit>().state;
    final length = state.message.trim().length;
    final reaction = state.status == FeedbackSubmissionStatus.submitting
        ? _Reaction.sending
        : length >= _meaningfulLength
        ? _Reaction.delighted
        : length > 0
        ? _Reaction.reading
        : _Reaction.forCategory(state.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: HeroineSpeechBubbleSwitcherWidget(
                    text: context.tr(reaction.bubbleKey),
                    highlight: reaction.highlight,
                    maxWidth: 220,
                    tailAtEnd: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            _PeekingHeroine(reaction: reaction),
            const SizedBox(width: AppSpacing.lg),
          ],
        ),
        CustomTextField(
          controller: controller,
          maxLines: 5,
          maxLength: 600,
          hintText: context.tr(state.category.hintKey),
          onChanged: context.read<FeedbackCubit>().updateMessage,
        ),
      ],
    );
  }
}

/// Only her upper half is shown: the card's top edge hides the rest, so she
/// looks like she is leaning over it.
class _PeekingHeroine extends StatelessWidget {
  const _PeekingHeroine({required this.reaction});

  final _Reaction reaction;

  static const double _width = 104;

  /// Fraction of her height above the card edge (her hands sit on it).
  static const double _visible = 0.5;

  @override
  Widget build(BuildContext context) {
    final visibleHeight = HeroineCharacterWidget.heightFor(_width) * _visible;
    return SizedBox(
      width: _width,
      height: visibleHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft halo behind her head.
          Positioned(
            left: 4,
            right: 4,
            top: -6,
            height: _width - 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.42), AppColors.primary.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: HeroineCharacterWidget(
                  width: _width,
                  pose: reaction.pose,
                  motion: reaction.motion,
                  prop: reaction.prop,
                ),
              ),
            ),
          ),
          // Floating "thought" emoji above her end shoulder (clear of the
          // waving hand).
          PositionedDirectional(
            end: -12,
            top: -24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 460),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: reaction.emoji == null
                  ? const SizedBox(key: ValueKey('none'), width: 34, height: 34)
                  : _ThoughtEmoji(key: ValueKey(reaction.emoji), emoji: reaction.emoji!),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThoughtEmoji extends StatelessWidget {
  const _ThoughtEmoji({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primarySoft, width: 1.5),
            boxShadow: AppShadows.floating,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 17)),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -5, duration: 1500.ms, curve: Curves.easeInOut)
        .rotate(begin: -0.03, end: 0.03, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

/// Her poses for this screen. Hand y ≈ 143 rests them right on the card edge
/// (her visible half ends at y = 150 in character space).
abstract final class _PeekPose {
  static const Offset _edgeLeft = Offset(94, 143);
  static const Offset _edgeRight = Offset(146, 143);

  /// Waving hello over the edge (new feature).
  static const hello = HeroinePose(
    leftHand: _edgeLeft,
    rightHand: Offset(176, 56),
    smile: 0.85,
    mouthOpen: 0.3,
    blush: 0.6,
    headTilt: 0.06,
  );

  /// Pointing up at her speech bubble (app lock options).
  static const pointBubble = HeroinePose(
    leftHand: Offset(34, 92),
    rightHand: _edgeRight,
    smile: 0.75,
    mouthOpen: 0.22,
    brows: 0.3,
    headTilt: -0.07,
    blush: 0.5,
  );

  /// Gently concerned, ready to help (bug report).
  static const concerned = HeroinePose(
    leftHand: _edgeLeft,
    rightHand: _edgeRight,
    smile: -0.12,
    mouthOpen: 0.12,
    brows: -0.55,
    headTilt: -0.08,
    blush: 0.2,
  );

  /// Eyes down on the text, smiling (typing).
  static const reading = HeroinePose(
    leftHand: _edgeLeft,
    rightHand: _edgeRight,
    lookDown: 0.4,
    smile: 0.55,
    blush: 0.55,
    headTilt: 0.05,
  );
}

class _Reaction {
  const _Reaction({
    required this.pose,
    required this.motion,
    required this.bubbleKey,
    this.prop = HeroineProp.none,
    this.emoji,
    this.highlight = false,
  });

  final HeroinePose pose;
  final HeroineMotion motion;
  final HeroineProp prop;
  final String bubbleKey;
  final String? emoji;

  /// Sky-gradient bubble (excited) instead of the calm white one.
  final bool highlight;

  static const reading = _Reaction(
    pose: _PeekPose.reading,
    motion: HeroineMotion.cherish,
    bubbleKey: 'feedback_bubble_reading',
    emoji: '✍️',
  );

  static const delighted = _Reaction(
    pose: HeroinePose.adore,
    motion: HeroineMotion.bounce,
    bubbleKey: 'feedback_bubble_delighted',
    emoji: '💙',
    highlight: true,
  );

  static const sending = _Reaction(
    pose: HeroinePose.cherishJoy,
    motion: HeroineMotion.cherish,
    prop: HeroineProp.heart,
    bubbleKey: 'feedback_bubble_sending',
    highlight: true,
  );

  static _Reaction forCategory(FeedbackCategory category) => switch (category) {
    FeedbackCategory.newFeature => const _Reaction(
      pose: _PeekPose.hello,
      motion: HeroineMotion.wave,
      bubbleKey: 'feedback_bubble_new_feature',
      emoji: '💡',
    ),
    FeedbackCategory.uiEnhancement => const _Reaction(
      pose: HeroinePose.adore,
      motion: HeroineMotion.bounce,
      bubbleKey: 'feedback_bubble_ui_enhancement',
      emoji: '🎨',
    ),
    FeedbackCategory.bugReport => const _Reaction(
      pose: _PeekPose.concerned,
      motion: HeroineMotion.idle,
      bubbleKey: 'feedback_bubble_bug_report',
      emoji: '🔍',
    ),
    FeedbackCategory.appLockOptions => const _Reaction(
      pose: _PeekPose.pointBubble,
      motion: HeroineMotion.idle,
      bubbleKey: 'feedback_bubble_app_lock_options',
      emoji: '🔒',
    ),
  };
}

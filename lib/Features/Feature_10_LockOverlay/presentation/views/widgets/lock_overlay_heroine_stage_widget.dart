import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../../core/widgets/sunburst_rays_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_speech_bubble_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/rising_emoji_particles_widget.dart';
import '../../manager/lock_overlay_cubit.dart';

/// The heroine's pep-talk, played as a short looping show so the lock never
/// feels like a wall:
///   hey (waves, "caught you!") → pep (points at the bubble: "just 5 min")
///   → scrub (washes a plate, soap bubbles) → dream (hugs a heart,
///   "a sparkling kitchen") → cheer (jumps: "you've got this!") → …
/// A new act every [_actLength]; tapping her skips ahead.
class LockOverlayHeroineStageWidget extends StatefulWidget {
  const LockOverlayHeroineStageWidget({super.key});

  @override
  State<LockOverlayHeroineStageWidget> createState() => _LockOverlayHeroineStageWidgetState();
}

enum _Act { hey, pep, scrub, dream, cheer }

class _LockOverlayHeroineStageWidgetState extends State<LockOverlayHeroineStageWidget> {
  static const Duration _actLength = Duration(milliseconds: 4200);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_actLength, (_) {
      if (mounted) context.read<LockOverlayCubit>().nextAct();
    });
  }

  void _skipAhead() {
    AppFunctions.lightHaptic();
    context.read<LockOverlayCubit>().nextAct();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _bubbleFor(BuildContext context, _Act act, LockOverlayState state) {
    final snapshot = state.snapshot;
    return switch (act) {
      _Act.hey =>
        snapshot.userName.isEmpty
            ? context.tr('lock_overlay_bubble_hey')
            : context.tr('lock_overlay_bubble_hey_name', {'name': snapshot.userName}),
      _Act.pep => context.tr('lock_overlay_bubble_pep', {'duration': context.minutes(snapshot.sprintMinutes)}),
      _Act.scrub => context.tr('lock_overlay_bubble_scrub'),
      _Act.dream => context.tr('lock_overlay_bubble_dream'),
      _Act.cheer => context.tr('lock_overlay_bubble_cheer'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LockOverlayCubit>().state;
    final act = _Act.values[state.actIndex % _Act.values.length];
    final (pose, motion, prop, particles) = switch (act) {
      _Act.hey => (HeroinePose.waveJoy, HeroineMotion.wave, HeroineProp.none, const ['👋', '✨']),
      _Act.pep => (HeroinePose.encourage, HeroineMotion.beckon, HeroineProp.none, const ['⏱️', '✨']),
      _Act.scrub => (HeroinePose.washJoy, HeroineMotion.scrub, HeroineProp.plate, const ['🫧', '🫧', '✨', '🫧']),
      _Act.dream => (HeroinePose.cherishJoy, HeroineMotion.cherish, HeroineProp.heart, const ['✨', '💙', '✨']),
      _Act.cheer => (HeroinePose.joyJump, HeroineMotion.jumpJoy, HeroineProp.none, const ['💪', '🎉', '💙', '✨']),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = constraints.maxHeight;
        final heroineHeight = math.min(stageHeight - 6, 290.0);
        final heroineWidth = heroineHeight * HeroinePainter.designWidth / HeroinePainter.designHeight;
        // A touch toward the start, leaving room for her bubble on the end side.
        final heroineStart = math.max(0.0, (stageWidth - heroineWidth) / 2 - stageWidth * 0.13);
        final bubbleStart = heroineStart + heroineWidth * 0.7;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Slowly turning sunrise rays + halo behind her.
            PositionedDirectional(
              start: heroineStart + heroineWidth / 2 - heroineHeight * 0.75,
              top: stageHeight - heroineHeight * 1.25,
              width: heroineHeight * 1.5,
              height: heroineHeight * 1.5,
              child: SunburstRaysWidget(
                color: act == _Act.cheer || act == _Act.dream ? const Color(0xFFFFD27A) : AppColors.primary,
              ),
            ),
            const Positioned.fill(child: FloatingSoapBubblesWidget(bubbleCount: 7, maxBubbleSize: 26)),
            PositionedDirectional(
              start: heroineStart,
              bottom: 0,
              child: Semantics(
                button: true,
                label: context.tr('lock_overlay_next_tip'),
                child: GestureDetector(
                  onTap: _skipAhead,
                  child: HeroineCharacterWidget(width: heroineWidth, pose: pose, motion: motion, prop: prop),
                ),
              ),
            ),
            // Little bursts rising from her hands, different for every act.
            PositionedDirectional(
              start: heroineStart + heroineWidth / 2 - 30,
              top: stageHeight - heroineHeight * 0.6,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                child: RisingEmojiParticlesWidget(
                  key: ValueKey(act),
                  emojis: particles,
                  rise: heroineHeight * 0.38,
                  spread: 30,
                  fontSize: 16,
                  interval: const Duration(milliseconds: 420),
                  lifetime: const Duration(milliseconds: 1700),
                ),
              ),
            ),
            if (stageHeight > 150)
              PositionedDirectional(
                start: bubbleStart,
                end: 0,
                top: math.max(0.0, stageHeight - heroineHeight - 6),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Semantics(
                    liveRegion: true,
                    child: HeroineSpeechBubbleSwitcherWidget(
                      text: _bubbleFor(context, act, state),
                      highlight: act != _Act.scrub,
                      maxWidth: math.max(120.0, stageWidth - bubbleStart),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

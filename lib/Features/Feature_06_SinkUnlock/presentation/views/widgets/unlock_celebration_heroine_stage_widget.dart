import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sunburst_rays_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_speech_bubble_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/rising_emoji_particles_widget.dart';

/// The heroine celebrates the clean sink with the user:
///   jump (padlock bursts open, "Yaaay, we did it!") → proud (hands under her
///   chin, "I'm so proud of you") → applause ("look at that sink") → cheer
///   ("now enjoy, guilt-free") → proud → …
/// Tapping her replays the jump and calls [onCelebrate] (e.g. more confetti).
class UnlockCelebrationHeroineStageWidget extends StatefulWidget {
  const UnlockCelebrationHeroineStageWidget({super.key, required this.userName, this.onCelebrate});

  final String userName;
  final VoidCallback? onCelebrate;

  @override
  State<UnlockCelebrationHeroineStageWidget> createState() => _UnlockCelebrationHeroineStageWidgetState();
}

enum _Beat { jump, proud, applause, cheer }

class _UnlockCelebrationHeroineStageWidgetState extends State<UnlockCelebrationHeroineStageWidget> {
  static const Duration _jumpLength = Duration(milliseconds: 2100);
  static const Duration _beatLength = Duration(milliseconds: 3800);
  static const List<_Beat> _loop = [_Beat.proud, _Beat.applause, _Beat.cheer];

  _Beat _beat = _Beat.jump;
  int _loopIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleAfterJump();
  }

  void _scheduleAfterJump() {
    _timer?.cancel();
    _timer = Timer(_jumpLength, () {
      if (!mounted) return;
      setState(() => _beat = _loop[_loopIndex % _loop.length]);
      _timer = Timer.periodic(_beatLength, (_) {
        if (mounted) setState(() => _beat = _loop[++_loopIndex % _loop.length]);
      });
    });
  }

  void _celebrateAgain() {
    AppFunctions.mediumHaptic();
    widget.onCelebrate?.call();
    setState(() => _beat = _Beat.jump);
    _scheduleAfterJump();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _bubble(BuildContext context) {
    final name = widget.userName;
    return switch (_beat) {
      _Beat.jump => context.tr('reward_bubble_jump'),
      _Beat.proud =>
        name.isEmpty ? context.tr('reward_bubble_proud') : context.tr('reward_bubble_proud_name', {'name': name}),
      _Beat.applause => context.tr('reward_bubble_sink'),
      _Beat.cheer => context.tr('reward_bubble_enjoy'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (pose, motion, particles) = switch (_beat) {
      _Beat.jump => (HeroinePose.joyJump, HeroineMotion.jumpJoy, const ['🎉', '💙', '✨', '💛', '🎉']),
      _Beat.proud => (HeroinePose.adore, HeroineMotion.bounce, const ['💙', '✨', '💙']),
      _Beat.applause => (HeroinePose.clapHappy, HeroineMotion.clap, const ['👏', '✨', '🫧']),
      _Beat.cheer => (HeroinePose.cheer, HeroineMotion.cheer, const ['🎉', '💖', '✨']),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = constraints.maxHeight;
        final heroineHeight = math.min(stageHeight - 6, 280.0);
        final heroineWidth = heroineHeight * HeroinePainter.designWidth / HeroinePainter.designHeight;
        final heroineStart = math.max(0.0, (stageWidth - heroineWidth) / 2 - stageWidth * 0.13);
        final bubbleStart = heroineStart + heroineWidth * 0.7;
        final badgeSize = (heroineHeight * 0.3).clamp(54.0, 76.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Mint-gold victory light behind her.
            PositionedDirectional(
              start: heroineStart + heroineWidth / 2 - heroineHeight * 0.8,
              top: stageHeight - heroineHeight * 1.3,
              width: heroineHeight * 1.6,
              height: heroineHeight * 1.6,
              child: SunburstRaysWidget(color: _beat == _Beat.jump ? const Color(0xFFFFD27A) : AppColors.success),
            ),
            // The padlock that just burst open, floating at her side (waist
            // height stays clear of every raised-arm pose).
            PositionedDirectional(
              start: math.max(0.0, heroineStart - badgeSize * 0.55),
              top: stageHeight - heroineHeight * 0.5,
              child: _BurstPadlock(size: badgeSize),
            ),
            PositionedDirectional(
              start: heroineStart,
              bottom: 0,
              child: Semantics(
                button: true,
                label: context.tr('reward_celebrate_again'),
                child: GestureDetector(
                  onTap: _celebrateAgain,
                  child: HeroineCharacterWidget(width: heroineWidth, pose: pose, motion: motion),
                ),
              ),
            ),
            PositionedDirectional(
              start: heroineStart + heroineWidth / 2 - 30,
              top: stageHeight - heroineHeight * 0.82,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                child: RisingEmojiParticlesWidget(
                  key: ValueKey(_beat),
                  emojis: particles,
                  rise: heroineHeight * 0.4,
                  spread: 36,
                  fontSize: 16,
                  interval: const Duration(milliseconds: 300),
                  lifetime: const Duration(milliseconds: 1600),
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
                      text: _bubble(context),
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

/// Glass orb whose padlock pops open (shackle up, elastic) with a green
/// glow ring, then keeps floating — the visual "you're free" beat.
class _BurstPadlock extends StatefulWidget {
  const _BurstPadlock({required this.size});

  final double size;

  @override
  State<_BurstPadlock> createState() => _BurstPadlockState();
}

class _BurstPadlockState extends State<_BurstPadlock> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      AppFunctions.lightHaptic();
      setState(() => _open = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Expanding ring when it unlocks.
          if (_open)
            Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                )
                .animate()
                .scaleXY(begin: 1, end: 1.9, duration: 700.ms, curve: Curves.easeOutCubic)
                .fadeOut(duration: 700.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: (_open ? AppColors.success : AppColors.primary).withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.elasticOut,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                _open ? Icons.lock_open_rounded : Icons.lock_rounded,
                key: ValueKey(_open),
                size: size * 0.46,
                color: _open ? AppColors.success : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -6, duration: 1700.ms, curve: Curves.easeInOut);
  }
}

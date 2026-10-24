import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'heroine_speech_bubble_widget.dart';
import 'rising_emoji_particles_widget.dart';

/// Paywall hero: the onboarding heroine acts as a friendly guide who SELLS
/// the plan — choreographed for conversion:
///  • Presents the offer (hand on hip, other hand open toward the plans).
///  • Annual picked → she JUMPS FOR JOY (both arms up, hearts rising), then
///    settles into a touched "hands under the chin" bounce.
///  • Weekly picked → still happy, calmer: a quick applause, then a friendly
///    hand-on-hip while the bubble gently nudges toward Annual.
///  • Every few seconds of hesitation she waves "psst… 3 days free".
///  • While the purchase runs she hugs a heart; on success she cheers.
class PaywallHeroineHeroWidget extends StatefulWidget {
  const PaywallHeroineHeroWidget({super.key, required this.celebrating, this.characterWidth = maxCharacterWidth});

  static const double maxCharacterWidth = 138;

  /// Purchase succeeded — play the celebration.
  final bool celebrating;

  /// Smaller on short phones so the whole paywall fits one screen; the speech
  /// bubble keeps its size (always readable).
  final double characterWidth;

  @override
  State<PaywallHeroineHeroWidget> createState() => _PaywallHeroineHeroWidgetState();
}

/// Short reaction played right after a plan is picked.
enum _PlanReaction { none, joy, applause }

class _PaywallHeroineHeroWidgetState extends State<PaywallHeroineHeroWidget> {
  static const Duration _nudgeEvery = Duration(seconds: 7);
  static const Duration _nudgeLength = Duration(milliseconds: 2200);
  static const Duration _joyLength = Duration(milliseconds: 1900); // ≈ 3 hops
  static const Duration _applauseLength = Duration(milliseconds: 1500);

  Timer? _nudgeTimer;
  Timer? _reactionTimer;
  bool _nudging = false;
  _PlanReaction _reaction = _PlanReaction.none;

  @override
  void initState() {
    super.initState();
    _nudgeTimer = Timer.periodic(_nudgeEvery, (_) {
      if (!mounted || widget.celebrating || _reaction != _PlanReaction.none) return;
      if (context.read<SubscriptionCubit>().state.isBusy) return;
      setState(() => _nudging = true);
      Future<void>.delayed(_nudgeLength, () {
        if (mounted) setState(() => _nudging = false);
      });
    });
    // Plans may already be loaded (paywall re-opened) → react right away.
    final selected = context.read<SubscriptionCubit>().state.selectedPlan;
    if (selected != null) _react(selected.isBestValue);
  }

  void _react(bool isBestValue) {
    _reactionTimer?.cancel();
    setState(() {
      _nudging = false;
      _reaction = isBestValue ? _PlanReaction.joy : _PlanReaction.applause;
    });
    _reactionTimer = Timer(isBestValue ? _joyLength : _applauseLength, () {
      if (mounted) setState(() => _reaction = _PlanReaction.none);
    });
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubscriptionCubit>().state;
    final selected = state.selectedPlan;
    final purchasing = state.status == SubscriptionStatus.purchasing;

    final annual = selected?.isBestValue ?? false;
    final planBubble = annual ? 'paywall_bubble_annual' : 'paywall_bubble_weekly';
    // Real saving of the annual plan (never a hard-coded number).
    final annualSaving = state.plans.where((plan) => plan.isBestValue).firstOrNull?.savingVsWeeklyPercent;
    final (pose, motion, prop, bubbleKey) = widget.celebrating
        ? (HeroinePose.cheer, HeroineMotion.cheer, HeroineProp.none, 'paywall_bubble_success')
        : purchasing
        ? (HeroinePose.cherishJoy, HeroineMotion.cherish, HeroineProp.heart, 'paywall_bubble_purchasing')
        : selected == null
        ? (HeroinePose.present, HeroineMotion.beckon, HeroineProp.none, 'paywall_bubble_loading')
        : _reaction == _PlanReaction.joy
        ? (HeroinePose.joyJump, HeroineMotion.jumpJoy, HeroineProp.none, planBubble)
        : _reaction == _PlanReaction.applause
        ? (HeroinePose.clapHappy, HeroineMotion.clap, HeroineProp.none, planBubble)
        : _nudging
        ? (HeroinePose.waveJoy, HeroineMotion.wave, HeroineProp.none, 'paywall_bubble_hey')
        : annual
        ? (HeroinePose.adore, HeroineMotion.bounce, HeroineProp.none, planBubble)
        : (HeroinePose.encourage, HeroineMotion.beckon, HeroineProp.none, planBubble);
    final warm = widget.celebrating || purchasing || annual;
    final showJoyParticles = _reaction == _PlanReaction.joy && !purchasing && !widget.celebrating;

    final characterWidth = widget.characterWidth;
    final height = HeroineCharacterWidget.heightFor(characterWidth);

    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) =>
          current.selectedPlan != null && previous.selectedPlan?.id != current.selectedPlan?.id,
      listener: (context, state) => _react(state.selectedPlan!.isBestValue),
      child: SizedBox(
        height: height + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Rotating light rays + halo behind her.
            PositionedDirectional(
              start: 0,
              top: -10,
              width: 230,
              height: height + 20,
              child: _GlowRays(warm: warm),
            ),
            PositionedDirectional(
              start: 46,
              bottom: 0,
              child: HeroineCharacterWidget(width: characterWidth, pose: pose, motion: motion, prop: prop),
            ),
            // Hearts & sparkles float up from her raised hands while she jumps.
            PositionedDirectional(
              start: 46 + characterWidth / 2 - 30,
              top: 18,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: showJoyParticles
                    ? const RisingEmojiParticlesWidget(
                        key: ValueKey('joy'),
                        emojis: ['💙', '✨', '💛', '✨', '💙'],
                        rise: 70,
                        spread: 34,
                        fontSize: 16,
                        interval: Duration(milliseconds: 260),
                        lifetime: Duration(milliseconds: 1500),
                      )
                    : const SizedBox(key: ValueKey('none'), width: 60, height: 20),
              ),
            ),
            // Twinkles around her.
            for (final (index, spot) in const [
              AlignmentDirectional(-0.95, -0.7),
              AlignmentDirectional(0.05, -0.95),
              AlignmentDirectional(-0.55, 0.55),
            ].indexed)
              Align(
                alignment: spot,
                child:
                    Icon(
                          Icons.auto_awesome_rounded,
                          size: 14.0 + index * 4,
                          color: index == 1 ? const Color(0xFFFFC857) : AppColors.primary,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true), delay: (index * 400).ms)
                        .scaleXY(begin: 0.4, end: 1.1, duration: 900.ms, curve: Curves.easeInOut)
                        .fadeIn(duration: 400.ms),
              ),
            // Speech bubble — swaps with a springy pop whenever the message changes.
            PositionedDirectional(
              end: 0,
              top: 6,
              child: HeroineSpeechBubbleSwitcherWidget(
                text: context.tr(bubbleKey, {'percent': '${annualSaving ?? ''}'}),
                highlight: warm,
                maxWidth: 158,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowRays extends StatefulWidget {
  const _GlowRays({required this.warm});

  final bool warm;

  @override
  State<_GlowRays> createState() => _GlowRaysState();
}

class _GlowRaysState extends State<_GlowRays> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 24))
    ..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.warm ? 1 : 0),
          duration: const Duration(milliseconds: 600),
          builder: (context, warmth, _) => CustomPaint(painter: _RaysPainter(_spin, warmth)),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.animation, this.warmth) : super(repaint: animation);

  final Animation<double> animation;
  final double warmth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);
    final radius = size.shortestSide * 0.62;
    final glow = Color.lerp(AppColors.primary, const Color(0xFFFFC7DA), warmth * 0.6)!;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [glow.withValues(alpha: 0.55), glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation.value * 2 * math.pi);
    final rayLength = radius * 1.25;
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final ray = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.09) * rayLength, math.sin(angle - 0.09) * rayLength)
        ..lineTo(math.cos(angle + 0.09) * rayLength, math.sin(angle + 0.09) * rayLength)
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (i.isEven ? const Color(0xFFFFE4A3) : Colors.white).withValues(alpha: 0.35 + 0.25 * warmth),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: rayLength)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => oldDelegate.warmth != warmth;
}

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

/// Paywall hero: the onboarding heroine acts as a friendly guide who SELLS
/// the plan — choreographed for conversion:
///  • Presents the offer (hand on hip, other hand pointing at the plans).
///  • Lights up with joy + "best value" bubble when Annual is selected,
///    and stays warm but nudges toward Annual if Monthly is picked.
///  • Every few seconds of hesitation she waves "psst… 3 days free".
///  • While the purchase runs she hugs a heart; on success she jumps for joy.
class PaywallHeroineHeroWidget extends StatefulWidget {
  const PaywallHeroineHeroWidget({super.key, required this.celebrating});

  /// Purchase succeeded — play the celebration.
  final bool celebrating;

  @override
  State<PaywallHeroineHeroWidget> createState() => _PaywallHeroineHeroWidgetState();
}

class _PaywallHeroineHeroWidgetState extends State<PaywallHeroineHeroWidget> {
  static const Duration _nudgeEvery = Duration(seconds: 7);
  static const Duration _nudgeLength = Duration(milliseconds: 2200);

  Timer? _nudgeTimer;
  bool _nudging = false;

  @override
  void initState() {
    super.initState();
    _nudgeTimer = Timer.periodic(_nudgeEvery, (_) {
      if (!mounted || widget.celebrating || context.read<SubscriptionCubit>().state.isBusy) return;
      setState(() => _nudging = true);
      Future<void>.delayed(_nudgeLength, () {
        if (mounted) setState(() => _nudging = false);
      });
    });
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubscriptionCubit>().state;
    final selected = state.selectedPlan;
    final purchasing = state.status == SubscriptionStatus.purchasing;

    final cue = _nudging ? HeroineMotion.wave : HeroineMotion.beckon;
    final (pose, motion, prop, bubbleKey) = widget.celebrating
        ? (HeroinePose.cheer, HeroineMotion.cheer, HeroineProp.none, 'paywall_bubble_success')
        : purchasing
        ? (HeroinePose.cherishJoy, HeroineMotion.cherish, HeroineProp.heart, 'paywall_bubble_purchasing')
        : selected == null
        ? (HeroinePose.present, HeroineMotion.beckon, HeroineProp.none, 'paywall_bubble_loading')
        : selected.isBestValue
        ? (HeroinePose.presentJoy, cue, HeroineProp.none, _nudging ? 'paywall_bubble_hey' : 'paywall_bubble_annual')
        : (HeroinePose.encourage, cue, HeroineProp.none, _nudging ? 'paywall_bubble_hey' : 'paywall_bubble_monthly');
    final warm = widget.celebrating || purchasing || (selected?.isBestValue ?? false);

    const characterWidth = 138.0;
    final height = HeroineCharacterWidget.heightFor(characterWidth);

    return SizedBox(
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                alignment: AlignmentDirectional.bottomStart.resolve(Directionality.of(context)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _SpeechBubble(key: ValueKey(bubbleKey), text: context.tr(bubbleKey), highlight: warm),
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
          constraints: const BoxConstraints(maxWidth: 158),
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

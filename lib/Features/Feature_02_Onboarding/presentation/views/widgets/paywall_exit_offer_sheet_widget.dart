import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'paywall_plan_card_widget.dart';

/// Opens the exit offer over the paywall (a partial sheet, not a new screen).
/// Resolves to `true` when the discounted plan was bought, otherwise to
/// `false` (sheet swiped away): the user simply stays on the paywall.
Future<bool> showPaywallExitOfferSheet(BuildContext context) async {
  final cubit = context.read<SubscriptionCubit>();
  final purchased = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: AppColors.ink.withValues(alpha: 0.38),
    builder: (_) => BlocProvider.value(value: cubit, child: const PaywallExitOfferSheetWidget()),
  );
  return purchased ?? false;
}

/// Shown every time the user taps "X" on the paywall.
///
/// Emotional choreography: the heroine (whom the user got to know through the
/// whole onboarding) peeks over the card and bursts into tears → wipes them
/// and holds out a gift: an extra discount on the annual plan → if the user
/// hesitates she pleads "pretty please?" → claim: she hugs a heart and jumps
/// for joy.
///
/// The paywall is strict: there is no "No thanks" — the only way forward is
/// to claim the offer (swiping the sheet away just returns to the paywall).
/// Store-safe on purpose: the struck-through price is the real regular price,
/// the billed price + renewal terms are spelled out, and there is no fake
/// countdown.
class PaywallExitOfferSheetWidget extends StatefulWidget {
  const PaywallExitOfferSheetWidget({super.key});

  /// How long she cries before the gift appears.
  static const Duration sobLength = Duration(milliseconds: 1900);

  @override
  State<PaywallExitOfferSheetWidget> createState() => _PaywallExitOfferSheetWidgetState();
}

enum _Phase { sob, gift, plead, purchasing, celebrate }

class _PaywallExitOfferSheetWidgetState extends State<PaywallExitOfferSheetWidget> {
  static const Duration _pleadEvery = Duration(seconds: 7);
  static const Duration _pleadLength = Duration(milliseconds: 2400);

  late final SubscriptionCubit _cubit = context.read<SubscriptionCubit>();
  _Phase _phase = _Phase.sob;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _cubit
      ..exitOfferShown()
      ..loadExitOffer();
    AppFunctions.mediumHaptic();
    _after(PaywallExitOfferSheetWidget.sobLength, () {
      AppFunctions.lightHaptic();
      _setPhase(_Phase.gift);
    });
    _timers.add(
      Timer.periodic(_pleadEvery, (_) {
        if (_phase != _Phase.gift) return;
        _setPhase(_Phase.plead);
        _after(_pleadLength, () {
          if (_phase == _Phase.plead) _setPhase(_Phase.gift);
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _after(Duration delay, VoidCallback action) => _timers.add(
    Timer(delay, () {
      if (mounted) action();
    }),
  );

  void _setPhase(_Phase phase) => setState(() => _phase = phase);

  Future<void> _claim() async {
    _setPhase(_Phase.purchasing);
    final purchased = await _cubit.purchaseExitOffer();
    if (!mounted) return;
    if (!purchased) return _setPhase(_Phase.gift);
    AppFunctions.successHaptic();
    _setPhase(_Phase.celebrate);
    _after(const Duration(milliseconds: 1100), () => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    final (pose, motion, prop, bubbleKey) = switch (_phase) {
      _Phase.sob => (HeroinePose.sob, HeroineMotion.sob, HeroineProp.none, 'exit_bubble_sob'),
      _Phase.gift => (HeroinePose.offerGift, HeroineMotion.bounce, HeroineProp.gift, 'exit_bubble_gift'),
      _Phase.plead => (HeroinePose.plead, HeroineMotion.plead, HeroineProp.none, 'exit_bubble_plead'),
      _Phase.purchasing => (HeroinePose.cherishJoy, HeroineMotion.cherish, HeroineProp.heart, 'exit_bubble_thanks'),
      _Phase.celebrate => (HeroinePose.joyJump, HeroineMotion.jumpJoy, HeroineProp.none, 'exit_bubble_yay'),
    };
    final isSad = _phase == _Phase.sob || _phase == _Phase.plead;
    final isRaining = _phase == _Phase.sob;

    const heroineWidth = 150.0;
    final heroineHeight = HeroineCharacterWidget.heightFor(heroineWidth);
    // She stands behind the card: her legs are hidden, she peeks over it.
    const stageHeight = 132.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Halo: cool and grey while she cries, warm once the gift appears.
        PositionedDirectional(
          start: 0,
          top: -18,
          width: 230,
          height: heroineHeight,
          child: IgnorePointer(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: isSad ? const Color(0xFFC9D6E8) : const Color(0xFFFFE1EC)),
              duration: AppDurations.slow,
              builder: (context, color, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [color!.withValues(alpha: 0.85), color.withValues(alpha: 0)]),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 40,
          top: 0,
          child: HeroineCharacterWidget(
            width: heroineWidth,
            pose: pose,
            motion: motion,
            prop: prop,
          ).animate().slideY(begin: 0.55, duration: 650.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms),
        ),
        // Little rain cloud over her head while she cries → sparkles after.
        PositionedDirectional(
          start: 40 + heroineWidth / 2 - 22,
          top: -34,
          child: AnimatedSwitcher(
            duration: AppDurations.slow,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: isRaining
                ? const _RainCloud(key: ValueKey('rain'))
                : _phase == _Phase.gift || _phase == _Phase.celebrate || _phase == _Phase.purchasing
                ? const Text(
                    '✨',
                    key: ValueKey('sparkle'),
                    style: TextStyle(fontSize: 26),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.8, end: 1.15, duration: 800.ms)
                : const SizedBox(key: ValueKey('none'), width: 44, height: 30),
          ),
        ),
        // Speech bubble right next to her, a little above her head: it starts
        // where her shoulder ends (its tail points back at her) and wraps its
        // text instead of overflowing on narrow phones.
        PositionedDirectional(
          start: 40 + heroineWidth - 26,
          end: AppSpacing.md,
          top: -26,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                alignment: AlignmentDirectional.bottomStart.resolve(Directionality.of(context)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _ExitBubble(key: ValueKey(bubbleKey), text: context.tr(bubbleKey), sad: isSad),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: stageHeight),
            Flexible(
              child: _OfferCard(
                showOfferPop: !isRaining,
                isBusy: _phase == _Phase.purchasing || _phase == _Phase.celebrate,
                onClaim: _claim,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.showOfferPop, required this.isBusy, required this.onClaim});

  final bool showOfferPop;
  final bool isBusy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final offer = context.select((SubscriptionCubit c) => c.state.exitOffer);
    final purchasing = context.select((SubscriptionCubit c) => c.state.status == SubscriptionStatus.purchasing);
    final percent = '${offer?.discountPercent ?? ''}';
    const radius = BorderRadius.vertical(top: Radius.circular(AppRadii.large));

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        borderRadius: radius,
        border: Border(top: BorderSide(color: Colors.white, width: 1.5)),
        boxShadow: [BoxShadow(color: Color(0x261F2A44), blurRadius: 30, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg - 4, AppSpacing.sm, AppSpacing.lg - 4, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withValues(alpha: 0.4),
                  borderRadius: AppRadii.pillAll,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFE1EC), Color(0xFFFFF1CC)]),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  context.tr('exit_offer_badge'),
                  style: AppTextStyles.label.copyWith(color: const Color(0xFFC2416B), letterSpacing: 0.2),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr('exit_offer_title', {'percent': percent}),
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(context.tr('exit_offer_subtitle'), textAlign: TextAlign.center, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.md + 4),
              if (offer == null)
                Container(
                  height: 84,
                  decoration: const BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadii.cardAll),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white)
              else
                PaywallPlanCardWidget(
                      plan: offer,
                      isSelected: true,
                      onTap: null,
                      badgeText: context.tr('exit_offer_extra_chip', {'percent': percent}),
                    )
                    .animate(target: showOfferPop ? 1 : 0)
                    .scaleXY(begin: 0.94, end: 1, duration: 650.ms, curve: Curves.elasticOut)
                    .fade(begin: 0.55, end: 1, duration: 300.ms),
              const SizedBox(height: AppSpacing.md),
              CustomPrimaryButton(
                label: context.tr('exit_offer_cta', {'percent': percent}),
                showShimmer: true,
                trailingIcon: Icons.card_giftcard_rounded,
                isLoading: purchasing,
                onPressed: offer == null || isBusy ? null : onClaim,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('paywall_auto_renew_note'),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExitBubble extends StatelessWidget {
  const _ExitBubble({super.key, required this.text, required this.sad});

  final String text;
  final bool sad;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: sad ? null : AppGradients.primaryButton,
              color: sad ? Colors.white : null,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                topEnd: Radius.circular(20),
                bottomEnd: Radius.circular(20),
                bottomStart: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: sad ? AppShadows.floating : AppShadows.primaryGlow(strength: 0.6),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 13.5,
                height: 1.3,
                color: sad ? AppColors.ink : AppColors.onPrimary,
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

/// A tiny grey cloud drizzling over her head while she cries.
class _RainCloud extends StatelessWidget {
  const _RainCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          for (final (index, dx) in const [-10.0, 0.0, 10.0].indexed)
            Positioned(
              top: 22,
              left: 22 + dx - 3,
              child:
                  Container(
                        width: 4,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8FD3F7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(), delay: (index * 220).ms)
                      .moveY(begin: 0, end: 20, duration: 700.ms, curve: Curves.easeIn)
                      .fadeOut(begin: 1, duration: 700.ms),
            ),
          const Text('☁️', style: TextStyle(fontSize: 30))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(begin: -2, end: 2, duration: 1300.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

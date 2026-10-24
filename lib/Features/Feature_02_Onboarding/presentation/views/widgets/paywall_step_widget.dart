import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/app_toast_widget.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../../core/widgets/glass_icon_button.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'paywall_plan_card_widget.dart' show PaywallPlanCardWidget;
import 'onboarding_step_header_widget.dart';
import 'heroine_character_widget.dart';
import 'paywall_exit_offer_sheet_widget.dart';
import 'paywall_heroine_hero_widget.dart';
import 'paywall_plan_card_widget.dart';

/// Screen 15 — Paywall (also hosted by the standalone PaywallView).
///
/// Always this custom Flutter design — never RevenueCat's paywall UI.
/// RevenueCat only feeds it: plans, purchase and restore all go through
/// [SubscriptionCubit] → SubscriptionRepo → data source, and every display is
/// reported with `paywallShown()` so paywall analytics / experiments work.
///
/// Conversion choreography: the heroine presents the offer and reacts to the
/// selected plan, the best-value card glows, the CTA breathes, trust chips
/// remove payment anxiety, and a successful purchase is celebrated.
///
/// STRICT paywall: there is no way past it except a purchase / restore.
/// Someone who is already subscribed (reinstall: the store remembered them)
/// skips it straight away.
/// "X" (or system back) opens the exit offer ([showPaywallExitOfferSheet]):
/// the heroine cries, then offers an extra discount on the annual plan. The
/// sheet has no decline button; swiping it away just returns here.
/// The standalone PaywallView ([isDismissible]) is only reachable from inside
/// the app, so there "X" simply closes it. At app open after the subscription
/// ended, PaywallView(strict) is non-dismissible like here.
/// The headline promises the free trial only when the selected plan really
/// has one: the stores give it once per account ([titleKey]).
class PaywallStepWidget extends StatefulWidget {
  const PaywallStepWidget({
    super.key,
    required this.userName,
    required this.onFinished,
    this.closeButtonDelay = const Duration(seconds: 3),
    this.isDismissible = false,
  });

  final String userName;

  /// Called with `true` after a successful purchase/restore (and with `false`
  /// only when [isDismissible] and the user closes the paywall).
  final ValueChanged<bool> onFinished;
  final Duration closeButtonDelay;

  /// Standalone paywall opened from inside the app: "X" just closes it.
  final bool isDismissible;

  static String titleKey({required bool hasTrial, required bool hasName}) => switch ((hasTrial, hasName)) {
    (true, true) => 'paywall_title',
    (true, false) => 'paywall_title_generic',
    (false, true) => 'paywall_title_subscribe',
    (false, false) => 'paywall_title_subscribe_generic',
  };

  @override
  State<PaywallStepWidget> createState() => _PaywallStepWidgetState();
}

class _PaywallStepWidgetState extends State<PaywallStepWidget> {
  bool _showCloseButton = false;
  bool _celebrating = false;
  bool _exitOfferOpen = false;

  // One screen, no scrolling: on shorter phones the heroine gets smaller (never
  // the prices, texts or buttons) until everything fits. Very small phones or
  // very large text still scroll as a last resort, so nothing is ever cut off.
  static const _heroMinWidth = 64.0;
  double _heroWidth = PaywallHeroineHeroWidget.maxCharacterWidth;

  /// The width the last layout used: the overflow a notification reports was
  /// measured with it (a newer [_heroWidth] may not be laid out yet).
  double _laidOutHeroWidth = PaywallHeroineHeroWidget.maxCharacterWidth;

  late final SubscriptionCubit _cubit = context.read<SubscriptionCubit>();

  @override
  void initState() {
    super.initState();
    // Already subscribed on this store account (e.g. reinstalled): no paywall.
    if (!widget.isDismissible && _cubit.state.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished(true);
      });
      return;
    }
    // Fresh every time: trial eligibility changes after a purchase / expiry.
    _cubit
      ..loadPaywall(force: true)
      ..paywallShown();
    // Preloaded so the exit offer opens instantly.
    _cubit.loadExitOffer(force: true);
    // A delayed close button keeps focus on the offer (common paywall practice).
    Future<void>.delayed(widget.closeButtonDelay, () {
      if (mounted) setState(() => _showCloseButton = true);
    });
  }

  Future<void> _purchase() async {
    final purchased = await _cubit.purchaseSelectedPlan();
    if (!purchased || !mounted) return;
    AppFunctions.successHaptic();
    await _celebrate();
  }

  Future<void> _celebrate() async {
    // Let the heroine celebrate with the user before moving on.
    setState(() => _celebrating = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) widget.onFinished(true);
  }

  Future<void> _restore() async {
    final restored = await _cubit.restorePurchases();
    if (restored) widget.onFinished(true);
  }

  /// "X" or system back: always the exit offer (strict paywall — the only
  /// way past it is buying; swiping the sheet away stays on the paywall).
  Future<void> _onExitAttempt() async {
    if (!_showCloseButton || _exitOfferOpen || _celebrating || _cubit.state.isBusy) return;
    if (widget.isDismissible) return widget.onFinished(false);
    setState(() => _exitOfferOpen = true);
    final purchased = await showPaywallExitOfferSheet(context);
    if (!mounted) return;
    setState(() => _exitOfferOpen = false);
    if (purchased) await _celebrate();
  }

  bool _shrinkHeroToFit(ScrollMetricsNotification notification) {
    final overflow = notification.metrics.maxScrollExtent;
    if (notification.depth != 0 || overflow < 1) return false;
    final width = (_laidOutHeroWidth - overflow / HeroineCharacterWidget.heightFor(1)).clamp(
      _heroMinWidth,
      PaywallHeroineHeroWidget.maxCharacterWidth,
    );
    // Sent after the frame, so a rebuild is allowed here. Only ever shrinks.
    if (width < _heroWidth) setState(() => _heroWidth = width);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _laidOutHeroWidth = _heroWidth;
    // Plans still loading: the trial headline, as before.
    final hasTrial = context.select((SubscriptionCubit c) => c.state.selectedPlan?.hasTrial ?? true);
    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) => current.failureKey != null && previous.failureKey != current.failureKey,
      listener: (context, state) {
        AppFunctions.showSnack(
          context,
          context.tr(state.failureKey!),
          tone: state.failureIsNotice ? AppToastTone.info : AppToastTone.error,
        );
        context.read<SubscriptionCubit>().clearFailure();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onExitAttempt();
        },
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingSoapBubblesWidget(bubbleCount: 8, maxBubbleSize: 30)),
            Column(
              children: [
                _PaywallTopBar(showClose: _showCloseButton, onClose: _onExitAttempt, onRestore: _restore),
                Expanded(
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: _shrinkHeroToFit,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hidden while the exit sheet shows her crying (one heroine at a time).
                          AnimatedOpacity(
                            opacity: _exitOfferOpen ? 0 : 1,
                            duration: AppDurations.medium,
                            child: PaywallHeroineHeroWidget(celebrating: _celebrating, characterWidth: _heroWidth),
                          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
                          OnboardingStepHeaderWidget(
                            title: context.tr(
                              PaywallStepWidget.titleKey(hasTrial: hasTrial, hasName: widget.userName.isNotEmpty),
                              {
                                // Bidi isolate: a Latin name inside Arabic text stays one
                                // unit, so its letters and the punctuation keep their order.
                                'name': '\u2068${widget.userName}\u2069',
                                'days': '${AppConstants.freeTrialDays}',
                              },
                            ),
                            highlight: widget.userName,
                            description: context.tr('paywall_subtitle'),
                            textAlign: TextAlign.center,
                          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),
                          // Plans first: both prices visible without scrolling (clarity
                          // converts better and is what App Review expects).
                          const SizedBox(height: AppSpacing.md + 6),
                          const _PaywallPlansSection().animate(delay: 200.ms).fadeIn().slideY(begin: 0.06),
                          const _PaywallTrustChips().animate(delay: 260.ms).fadeIn(),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
                _PaywallBottomActions(onPurchase: _purchase).animate(delay: 380.ms).fadeIn().slideY(begin: 0.3),
              ],
            ),
            if (_celebrating) const Positioned.fill(child: ConfettiBurstWidget(particleCount: 90)),
          ],
        ),
      ),
    );
  }
}

class _PaywallTopBar extends StatelessWidget {
  const _PaywallTopBar({required this.showClose, required this.onClose, required this.onRestore});

  final bool showClose;
  final VoidCallback onClose;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final isRestoring = context.select((SubscriptionCubit c) => c.state.status == SubscriptionStatus.restoring);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      child: Row(
        children: [
          TextButton(
            onPressed: isRestoring ? null : onRestore,
            child: Text(
              isRestoring ? context.tr('restoring') : context.tr('restore_purchases'),
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: showClose ? 1 : 0,
            duration: AppDurations.slow,
            child: IgnorePointer(
              ignoring: !showClose,
              child: GlassIconButton(
                icon: Icons.close_rounded,
                size: 38,
                iconColor: AppColors.inkMuted,
                semanticLabel: context.tr('close'),
                onPressed: onClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallTrustChips extends StatelessWidget {
  const _PaywallTrustChips();

  @override
  Widget build(BuildContext context) {
    // The billing reminder exists for free trials only.
    final hasTrial = context.select((SubscriptionCubit c) => c.state.selectedPlan?.hasTrial ?? true);
    final chips = [
      (Icons.event_available_rounded, 'paywall_trust_cancel'),
      if (hasTrial) (Icons.notifications_active_rounded, 'paywall_trust_reminder'),
      (Icons.lock_rounded, 'paywall_trust_secure'),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (icon, key) in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: AppRadii.pillAll,
              border: Border.all(color: Colors.white),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: AppColors.success),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    context.tr(key),
                    style: AppTextStyles.label.copyWith(color: AppColors.ink, fontSize: 10.5, letterSpacing: 0),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaywallPlansSection extends StatelessWidget {
  const _PaywallPlansSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      buildWhen: (previous, current) =>
          previous.plans != current.plans ||
          previous.selectedPlanId != current.selectedPlanId ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.plans.isEmpty && state.status == SubscriptionStatus.failure) {
          return Center(
            child: TextButton.icon(
              onPressed: () => context.read<SubscriptionCubit>().loadPaywall(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('retry')),
            ),
          );
        }
        if (state.plans.isEmpty) return const _PlanSkeletons();
        return Column(
          children: [
            for (final plan in state.plans)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md - 2),
                child: PaywallPlanCardWidget(
                  plan: plan,
                  isSelected: plan.id == state.selectedPlan?.id,
                  onTap: () => context.read<SubscriptionCubit>().selectPlan(plan.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanSkeletons extends StatelessWidget {
  const _PlanSkeletons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            height: 78,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: AppRadii.cardAll),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.primarySoft),
      ],
    );
  }
}

class _PaywallBottomActions extends StatelessWidget {
  const _PaywallBottomActions({required this.onPurchase});

  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubscriptionCubit>().state;
    final plan = state.selectedPlan;
    // Trial wording only when the selected plan really has a free trial.
    final hasTrial = plan?.hasTrial ?? true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.xs,
        AppSpacing.screenGutter,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTrial)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('paywall_no_payment_now'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          // The CTA "breathes" softly so the eye keeps coming back to it.
          CustomPrimaryButton(
                label: context.tr(hasTrial ? 'paywall_cta' : 'paywall_cta_subscribe'),
                showShimmer: true,
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: state.status == SubscriptionStatus.purchasing,
                onPressed: state.selectedPlan == null || state.isBusy ? null : onPurchase,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.025, duration: 1100.ms, curve: Curves.easeInOut),
          const SizedBox(height: AppSpacing.xs),
          if (plan != null)
            Text(
              PaywallPlanCardWidget.billingNote(context, plan),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FooterLink(label: context.tr('terms_of_use'), url: AppConstants.termsUrl),
              Text('·', style: AppTextStyles.caption),
              _FooterLink(label: context.tr('privacy_policy'), url: AppConstants.privacyUrl),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 30)),
      // Both stores require working Terms / Privacy links on the paywall.
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
      child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11.5, decoration: TextDecoration.underline)),
    );
  }
}

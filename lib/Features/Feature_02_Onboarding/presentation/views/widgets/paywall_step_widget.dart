import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/glass_icon_button.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'onboarding_step_header_widget.dart';
import 'paywall_plan_card_widget.dart';

/// Screen 15 — Paywall (also hosted by the standalone PaywallView).
///
/// Adapty-ready: plans, purchase and restore all go through
/// [SubscriptionCubit] → SubscriptionRepo → data source. When
/// `AppConstants.useAdaptyPaywallBuilder` is enabled, this widget is the place
/// to present `AdaptyUI` instead of the native layout below.
class PaywallStepWidget extends StatefulWidget {
  const PaywallStepWidget({
    super.key,
    required this.userName,
    required this.onFinished,
    this.closeButtonDelay = const Duration(seconds: 3),
  });

  final String userName;

  /// Called with `true` after a successful purchase/restore, `false` when
  /// the user dismisses the paywall.
  final ValueChanged<bool> onFinished;
  final Duration closeButtonDelay;

  @override
  State<PaywallStepWidget> createState() => _PaywallStepWidgetState();
}

class _PaywallStepWidgetState extends State<PaywallStepWidget> {
  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionCubit>().loadPaywall();
    // A delayed close button keeps focus on the offer (common paywall practice).
    Future<void>.delayed(widget.closeButtonDelay, () {
      if (mounted) setState(() => _showCloseButton = true);
    });
  }

  Future<void> _purchase() async {
    final purchased = await context.read<SubscriptionCubit>().purchaseSelectedPlan();
    if (purchased) {
      AppFunctions.successHaptic();
      widget.onFinished(true);
    }
  }

  Future<void> _restore() async {
    final restored = await context.read<SubscriptionCubit>().restorePurchases();
    if (restored) widget.onFinished(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) => current.failureKey != null && previous.failureKey != current.failureKey,
      listener: (context, state) {
        AppFunctions.showSnack(context, context.tr(state.failureKey!));
        context.read<SubscriptionCubit>().clearFailure();
      },
      child: Column(
        children: [
          _PaywallTopBar(showClose: _showCloseButton, onClose: () => widget.onFinished(false), onRestore: _restore),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: GlassIconOrbWidget(icon: Icons.water_drop_rounded, size: 60))
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
                  OnboardingStepHeaderWidget(
                    title: widget.userName.isEmpty
                        ? context.tr('paywall_title_generic', {'days': '${AppConstants.freeTrialDays}'})
                        : context.tr('paywall_title', {
                            'name': widget.userName,
                            'days': '${AppConstants.freeTrialDays}',
                          }),
                    highlight: widget.userName,
                    description: context.tr('paywall_subtitle'),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),
                  // Plans first: both prices visible without scrolling (clarity
                  // converts better and is what App Review expects).
                  const SizedBox(height: AppSpacing.md + 6),
                  const _PaywallPlansSection().animate(delay: 200.ms).fadeIn().slideY(begin: 0.06),
                  const _PaywallFeatureList().animate(delay: 300.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          _PaywallBottomActions(onPurchase: _purchase).animate(delay: 380.ms).fadeIn().slideY(begin: 0.3),
        ],
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

class _PaywallFeatureList extends StatelessWidget {
  const _PaywallFeatureList();

  @override
  Widget build(BuildContext context) {
    const features = [
      ('🔒', 'paywall_feature_smart_lock'),
      ('📸', 'paywall_feature_photo_unlock'),
      ('🗓️', 'paywall_feature_unlimited'),
      ('🔥', 'paywall_feature_streaks'),
    ];
    return CustomCardContainer(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (final (emoji, key) in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(context.tr(key), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14.5))),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ],
              ),
            ),
        ],
      ),
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
    const days = '${AppConstants.freeTrialDays}';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                context.tr('paywall_no_payment_now'),
                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomPrimaryButton(
            label: context.tr('paywall_cta'),
            showShimmer: true,
            isLoading: state.status == SubscriptionStatus.purchasing,
            onPressed: state.selectedPlan == null || state.isBusy ? null : onPurchase,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('paywall_note', {'days': days}),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(label: context.tr('terms_of_use')),
              Text('·', style: AppTextStyles.caption),
              _FooterLink(label: context.tr('privacy_policy')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 30)),
      // TODO(legal): open AppConstants.termsUrl / privacyUrl with url_launcher.
      onPressed: () {},
      child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11.5, decoration: TextDecoration.underline)),
    );
  }
}

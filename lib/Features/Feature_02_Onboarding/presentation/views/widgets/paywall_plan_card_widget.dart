import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../Feature_04_Subscription/data/models/subscription_plan_model.dart';

/// Selectable glass plan card (Annual / Monthly).
///
/// Selected state is unmistakable and premium: the card lifts, a light runs
/// around its border, the radio springs in and the per-week price grows.
/// The "Save X%" ribbon shimmers to anchor attention on the best value.
class PaywallPlanCardWidget extends StatelessWidget {
  const PaywallPlanCardWidget({super.key, required this.plan, required this.isSelected, required this.onTap});

  final SubscriptionPlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAnnual = plan.period == SubscriptionPeriod.annual;
    final title = context.tr(isAnnual ? 'plan_annual_title' : 'plan_monthly_title');
    final priceLine = context.tr(isAnnual ? 'plan_trial_then_year' : 'plan_trial_then_month', {
      'days': '${plan.trialDays}',
      'price': plan.localizedPrice,
    });

    final card = AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardAll,
        boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.6) : const [],
      ),
      child: CustomCardContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
        fillColor: isSelected ? Colors.white.withValues(alpha: 0.96) : AppColors.glassFill,
        borderColor: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.glassBorder,
        borderWidth: 1.2,
        child: Row(
          children: [
            _PlanRadio(isSelected: isSelected),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap: on narrow phones / large text the badge drops under the title.
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.titleSmall.copyWith(fontSize: 17)),
                      if (plan.isBestValue) const _BestValueChip(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(priceLine, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AnimatedScale(
              scale: isSelected ? 1.08 : 1,
              duration: AppDurations.medium,
              curve: Curves.easeOutBack,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.localizedPricePerWeek,
                    style: AppTextStyles.title.copyWith(color: isSelected ? AppColors.primaryInk : AppColors.ink),
                  ),
                  Text(context.tr('plan_per_week'), style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: '$title, $priceLine',
      child: AnimatedScale(
        scale: isSelected ? 1 : 0.97,
        duration: AppDurations.medium,
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelected) _RunningLightBorder(child: card) else card,
            if (plan.discountPercent != null)
              PositionedDirectional(
                top: -12,
                end: 18,
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: const BoxDecoration(
                            gradient: AppGradients.ink,
                            borderRadius: AppRadii.pillAll,
                            boxShadow: AppShadows.soft,
                          ),
                          child: Text(
                            context.tr('plan_save_badge', {'percent': '${plan.discountPercent}'}),
                            style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 10.5),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(delay: 1600.ms, duration: 1200.ms, color: Colors.white.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BestValueChip extends StatelessWidget {
  const _BestValueChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(color: Color(0xFFFFF1CC), borderRadius: AppRadii.pillAll),
      child: Text(
        '⭐ ${context.tr('plan_best_value')}',
        style: AppTextStyles.label.copyWith(color: const Color(0xFFB7791F), fontSize: 9.5, letterSpacing: 0.2),
      ),
    );
  }
}

/// A soft highlight that travels around the card border forever.
class _RunningLightBorder extends StatefulWidget {
  const _RunningLightBorder({required this.child});

  final Widget child;

  @override
  State<_RunningLightBorder> createState() => _RunningLightBorderState();
}

class _RunningLightBorderState extends State<_RunningLightBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(foregroundPainter: _BorderLightPainter(_spin), child: widget.child);
  }
}

class _BorderLightPainter extends CustomPainter {
  _BorderLightPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.2);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(AppRadii.card));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = SweepGradient(
          colors: const [AppColors.primary, AppColors.primaryDeep, Colors.white, AppColors.primary, AppColors.primary],
          stops: const [0, 0.18, 0.26, 0.36, 1],
          transform: GradientRotation(animation.value * 2 * math.pi),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BorderLightPainter oldDelegate) => false;
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected ? AppGradients.primaryButton : null,
        color: isSelected ? null : Colors.white,
        border: Border.all(color: isSelected ? Colors.white : AppColors.divider, width: 2),
        boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.4) : null,
      ),
      child: AnimatedScale(
        scale: isSelected ? 1 : 0,
        duration: AppDurations.medium,
        curve: Curves.elasticOut,
        child: const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
      ),
    );
  }
}

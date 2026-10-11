import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../Feature_04_Subscription/data/models/subscription_plan_model.dart';

/// Selectable glass plan card (Annual / Monthly) with a "Save X%" ribbon and
/// the per-week price anchor that makes the annual plan feel tiny.
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

    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: '$title, $priceLine',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardAll,
              boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.55) : const [],
            ),
            child: CustomCardContainer(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
              fillColor: isSelected ? AppColors.primarySoft.withValues(alpha: 0.95) : AppColors.glassFill,
              borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
              borderWidth: isSelected ? 2 : 1.2,
              child: Row(
                children: [
                  _PlanRadio(isSelected: isSelected),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.titleSmall.copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(priceLine, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.localizedPricePerWeek,
                        style: AppTextStyles.title.copyWith(color: isSelected ? AppColors.primaryInk : AppColors.ink),
                      ),
                      Text(context.tr('plan_per_week'), style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (plan.discountPercent != null)
            PositionedDirectional(
              top: -11,
              end: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  gradient: AppGradients.ink,
                  borderRadius: AppRadii.pillAll,
                  boxShadow: AppShadows.soft,
                ),
                child: Text(
                  context.tr('plan_save_badge', {'percent': '${plan.discountPercent}'}),
                  style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 10.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
      ),
      child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary) : null,
    );
  }
}

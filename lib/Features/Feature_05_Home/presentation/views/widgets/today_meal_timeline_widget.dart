import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../data/models/home_dashboard_model.dart';

/// Today's meal locks as a compact horizontal timeline with status chips.
class TodayMealTimelineWidget extends StatelessWidget {
  const TodayMealTimelineWidget({super.key, required this.meals, required this.onEditSchedule});

  final List<TodayMealStatusModel> meals;
  final VoidCallback onEditSchedule;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: meals.isEmpty
          ? Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(context.tr('home_rest_day'), style: AppTextStyles.bodyStrong)),
                TextButton(onPressed: onEditSchedule, child: Text(context.tr('edit'))),
              ],
            )
          : Row(
              children: [
                for (final (index, meal) in meals.indexed) ...[
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 34),
                        decoration: const BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadii.pillAll),
                      ),
                    ),
                  _MealNode(meal: meal),
                ],
              ],
            ),
    );
  }
}

class _MealNode extends StatelessWidget {
  const _MealNode({required this.meal});

  final TodayMealStatusModel meal;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (meal.status) {
      TodayMealStatus.cleaned => (Icons.check_rounded, AppColors.success, AppColors.successSoft),
      TodayMealStatus.locked => (Icons.lock_rounded, AppColors.danger, AppColors.dangerSoft),
      TodayMealStatus.upcoming => (Icons.schedule_rounded, AppColors.primaryInk, AppColors.primarySoft),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(meal.meal.translationKey),
          style: AppTextStyles.caption.copyWith(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        Text(AppFunctions.formatDateTimeClock(context, meal.at), style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

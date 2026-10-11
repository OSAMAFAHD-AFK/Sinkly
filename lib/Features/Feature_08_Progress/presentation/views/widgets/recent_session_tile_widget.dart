import 'package:flutter/material.dart';

import '../../../../../core/models/sink_cleaning_session_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';

/// One row in the cleaning history list.
class RecentSessionTileWidget extends StatelessWidget {
  const RecentSessionTileWidget({super.key, required this.session, required this.today});

  final SinkCleaningSessionModel session;
  final DateTime today;

  String _dayLabel(BuildContext context) {
    final day = AppFunctions.startOfDay(session.completedAt);
    final difference = today.difference(day).inDays;
    if (difference == 0) return context.tr('today');
    if (difference == 1) return context.tr('yesterday');
    return context.tr(AppFunctions.weekdayLongKey(day.weekday));
  }

  @override
  Widget build(BuildContext context) {
    final meal = session.triggeringMeal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal == null
                      ? context.tr('session_manual_clean')
                      : context.tr('session_after_meal', {'meal': context.tr(meal.translationKey)}),
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                ),
                Text(
                  '${_dayLabel(context)} · ${AppFunctions.formatDateTimeClock(context, session.completedAt)}',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadii.pillAll),
            child: Text(
              AppFunctions.formatCountdown(session.cleaningDuration.inSeconds.clamp(0, 99 * 60)),
              style: AppTextStyles.label.copyWith(color: AppColors.primaryInk, letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}

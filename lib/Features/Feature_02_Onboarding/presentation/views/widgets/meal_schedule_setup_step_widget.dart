import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../manager/onboarding_cubit.dart';
import '../../../../../core/utils/style.dart';
import 'animated_clock_widget.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'schedule_meal_picker_matrix_widget.dart';

/// Screen 8 — "Disaster days" + meals per day + meal end times, unified.
class MealScheduleSetupStepWidget extends StatelessWidget {
  const MealScheduleSetupStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final schedule = context.select((OnboardingCubit c) => c.state.preferences.schedule);

    return OnboardingStepScaffoldWidget(
      illustration: const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xs),
        child: AnimatedClockWidget(size: 76, secondsPerTurn: 6, showLockBadge: true),
      ),
      title: context.tr('schedule_title'),
      ctaLabel: context.tr('schedule_save_cta'),
      onCtaPressed: schedule.hasActiveDays ? cubit.nextStep : null,
      body: ScheduleMealPickerMatrixWidget(
        schedule: schedule,
        onDayToggled: cubit.toggleScheduleDay,
        onMealToggled: cubit.setMealEnabled,
        onMealTimeChanged: cubit.setMealTime,
        onSyncAllDaysWith: cubit.syncAllDaysWith,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../manager/onboarding_cubit.dart';
import 'hourglass_sand_widget.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'time_loss_comparison_chart_widget.dart';

/// Screen 7 — the time-loss reveal, shown straight away (no "analyzing"
/// wait): the hourglass races, then the comparison chart and the weekly /
/// yearly cost animate in.
class TimeLossFrictionAnalysisStepWidget extends StatelessWidget {
  const TimeLossFrictionAnalysisStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select((OnboardingCubit c) => c.state.preferences.trimmedName);
    final duration = context.minutes(AppConstants.sinkSprintDuration.inMinutes);

    return OnboardingStepScaffoldWidget(
      illustration: const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: HourglassSandWidget(height: 112, urgent: true),
      ),
      title: context.tr('time_loss_title', {'name': name, 'duration': duration}),
      highlight: name,
      description: context.tr('time_loss_description', {'duration': duration}),
      ctaLabel: context.tr('time_loss_cta'),
      onCtaPressed: context.read<OnboardingCubit>().nextStep,
      body: const TimeLossComparisonChartWidget(),
    );
  }
}

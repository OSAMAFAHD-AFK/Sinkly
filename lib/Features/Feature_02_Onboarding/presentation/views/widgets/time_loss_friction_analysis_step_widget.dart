import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../manager/onboarding_cubit.dart';
import 'analysis_progress_checklist_widget.dart';
import 'hourglass_sand_widget.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'time_loss_comparison_chart_widget.dart';

/// Screen 7 — Interactive friction analysis. A short "analyzing your
/// answers" moment, then the time-loss reveal.
class TimeLossFrictionAnalysisStepWidget extends StatefulWidget {
  const TimeLossFrictionAnalysisStepWidget({super.key});

  @override
  State<TimeLossFrictionAnalysisStepWidget> createState() => _TimeLossFrictionAnalysisStepWidgetState();
}

class _TimeLossFrictionAnalysisStepWidgetState extends State<TimeLossFrictionAnalysisStepWidget> {
  bool _analysisDone = false;

  void _onAnalysisCompleted() {
    if (!mounted) return;
    AppFunctions.lightHaptic();
    setState(() => _analysisDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select((OnboardingCubit c) => c.state.preferences.trimmedName);

    return OnboardingStepScaffoldWidget(
      // Frantic clock while analyzing, calmer once the result is shown.
      illustration: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        // Sand drains calmly while analyzing, then races once the loss is revealed.
        child: HourglassSandWidget(height: 112, urgent: _analysisDone),
      ),
      title: context.tr('time_loss_title', {
        'name': name,
        'duration': context.minutes(AppConstants.sinkSprintDuration.inMinutes),
      }),
      highlight: name,
      description: context.tr('time_loss_description', {
        'duration': context.minutes(AppConstants.sinkSprintDuration.inMinutes),
      }),
      ctaLabel: context.tr('time_loss_cta'),
      onCtaPressed: _analysisDone ? context.read<OnboardingCubit>().nextStep : null,
      body: AnimatedSwitcher(
        duration: AppDurations.slow,
        switchInCurve: Curves.easeOutCubic,
        child: _analysisDone
            ? const TimeLossComparisonChartWidget()
            : AnalysisProgressChecklistWidget(
                title: context.tr('analysis_title'),
                emojis: const ['📝', '⏳', '🎯'],
                items: [
                  context.tr('analysis_item_answers'),
                  context.tr('analysis_item_avoidance'),
                  context.tr('analysis_item_reclaim'),
                ],
                onCompleted: _onAnalysisCompleted,
              ),
      ),
    );
  }
}

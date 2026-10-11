import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'sinkly_formula_flow_widget.dart';

/// Screen 11 — The Sinkly paradigm shift: "No social media until the sink
/// is clean". Uses the user's own selected apps in the visual.
class SinklySolutionExplainerStepWidget extends StatelessWidget {
  const SinklySolutionExplainerStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appIds = context.select((OnboardingCubit c) => c.state.preferences.blockedAppIds);
    return OnboardingStepScaffoldWidget(
      title: context.tr('solution_title'),
      description: context.tr('solution_description'),
      ctaLabel: context.tr('solution_cta'),
      onCtaPressed: context.read<OnboardingCubit>().nextStep,
      body: SinklyFormulaFlowWidget(blockedApps: BlockableAppModel.fromIds(appIds)),
    );
  }
}

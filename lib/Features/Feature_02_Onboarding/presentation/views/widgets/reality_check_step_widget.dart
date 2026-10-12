import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../manager/onboarding_cubit.dart';
import 'clean_kitchen_reveal_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 4 — A reality check: what peace of mind is worth.
class RealityCheckStepWidget extends StatelessWidget {
  const RealityCheckStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffoldWidget(
      illustration: const CleanKitchenRevealWidget(),
      title: context.tr('reality_check_title'),
      description: context.tr('reality_check_description'),
      ctaLabel: context.tr('reality_check_cta'),
      onCtaPressed: context.read<OnboardingCubit>().nextStep,
    );
  }
}

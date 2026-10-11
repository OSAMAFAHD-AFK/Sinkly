import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'phone_escape_illustration_widget.dart';

/// Screen 3 — Uncovering the emotional issue (personalized pain point).
class EmotionalPainPointStepWidget extends StatelessWidget {
  const EmotionalPainPointStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select((OnboardingCubit c) => c.state.preferences.trimmedName);
    return OnboardingStepScaffoldWidget(
      illustration: const PhoneEscapeIllustrationWidget(),
      title: context.tr('pain_point_title', {'name': name}),
      highlight: name,
      description: context.tr('pain_point_description'),
      ctaLabel: context.tr('pain_point_cta'),
      onCtaPressed: context.read<OnboardingCubit>().nextStep,
    );
  }
}

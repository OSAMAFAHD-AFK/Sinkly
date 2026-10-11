import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../../data/models/onboarding_quiz_option_model.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';
import 'quiz_option_card_widget.dart';

/// Screen 5 — Diagnosing the struggle (how long dishes pile up).
class DishPileupDiagnosisQuizStepWidget extends StatelessWidget {
  const DishPileupDiagnosisQuizStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final selectedId = context.select((OnboardingCubit c) => c.state.preferences.dishPileupSeverityId);

    return OnboardingStepScaffoldWidget(
      illustration: const GlassIconOrbWidget(emoji: '🧽', size: 92),
      title: context.tr('quiz_pileup_title'),
      description: context.tr('quiz_single_choice_hint'),
      ctaLabel: context.tr('continue'),
      onCtaPressed: selectedId == null ? null : cubit.nextStep,
      body: Column(
        children: [
          for (final (index, option) in OnboardingQuizOptionModel.dishPileupSeverityOptions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: QuizOptionCardWidget(
                emoji: option.emoji,
                label: context.tr(option.translationKey),
                isSelected: option.id == selectedId,
                onTap: () => cubit.selectDishPileupSeverity(option.id),
              ).animate(delay: (120 + index * 80).ms).fadeIn().slideX(begin: 0.08, curve: Curves.easeOutCubic),
            ),
        ],
      ),
    );
  }
}

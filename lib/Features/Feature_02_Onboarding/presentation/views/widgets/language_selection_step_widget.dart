import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/supported_language_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../manager/onboarding_cubit.dart';
import 'language_card_selection_widget.dart';
import 'language_orbit_globe_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 1 — Preferred language. The device language is detected and its
/// card pre-selected automatically; tapping a card previews it live.
class LanguageSelectionStepWidget extends StatelessWidget {
  const LanguageSelectionStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final selectedCode = context.select((OnboardingCubit c) => c.state.preferences.languageCode);
    final deviceCode = LocaleController.deviceLanguageCode();

    return OnboardingStepScaffoldWidget(
      illustration: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: LanguageOrbitGlobeWidget(selectedCode: selectedCode),
      ),
      title: context.tr('choose_language_title'),
      description: context.tr('choose_language_subtitle'),
      ctaLabel: context.tr('continue'),
      onCtaPressed: cubit.confirmLanguage,
      body: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: SupportedLanguageModel.all.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 66,
        ),
        itemBuilder: (context, index) {
          final language = SupportedLanguageModel.all[index];
          return LanguageCardSelectionWidget(
            language: language,
            isSelected: language.code == selectedCode,
            isDeviceLanguage: language.code == deviceCode,
            deviceBadgeLabel: context.tr('device_language_badge'),
            onTap: () => cubit.selectLanguage(language.code),
          ).animate(delay: (40 * index).ms).fadeIn(duration: 300.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

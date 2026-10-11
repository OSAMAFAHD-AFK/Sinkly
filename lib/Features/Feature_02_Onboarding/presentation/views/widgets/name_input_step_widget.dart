import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 2 — The name & hook. The CTA becomes "Continue, {name}" as the
/// user types, an instant moment of personalization.
class NameInputStepWidget extends StatefulWidget {
  const NameInputStepWidget({super.key});

  @override
  State<NameInputStepWidget> createState() => _NameInputStepWidgetState();
}

class _NameInputStepWidgetState extends State<NameInputStepWidget> {
  late final TextEditingController _nameController = TextEditingController(
    text: context.read<OnboardingCubit>().state.preferences.userName,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<OnboardingCubit>();
    if (!cubit.state.canContinueFromName) return;
    FocusScope.of(context).unfocus();
    cubit.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select((OnboardingCubit c) => c.state.preferences.trimmedName);

    return OnboardingStepScaffoldWidget(
      illustration: const GlassIconOrbWidget(emoji: '👋', size: 104),
      title: context.tr('name_question_title'),
      description: context.tr('name_question_description'),
      ctaLabel: name.isEmpty ? context.tr('continue') : context.tr('continue_with_name', {'name': name}),
      onCtaPressed: name.isEmpty ? null : _submit,
      body: CustomTextField(
        controller: _nameController,
        hintText: context.tr('name_hint'),
        prefixIcon: Icons.person_outline_rounded,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        textStyle: AppTextStyles.title,
        onChanged: context.read<OnboardingCubit>().updateName,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

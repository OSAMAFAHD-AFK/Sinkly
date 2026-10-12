import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../manager/onboarding_cubit.dart';
import 'name_greeting_scene_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 2 — The name & hook.
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
      illustration: NameGreetingSceneWidget(name: name),
      title: context.tr('name_question_title'),
      description: context.tr('name_question_description'),
      ctaLabel: context.tr('continue'),
      onCtaPressed: name.isEmpty ? null : _submit,
      body: CustomTextField(
        controller: _nameController,
        hintText: context.tr('name_hint'),
        prefixIcon: Icons.person_outline_rounded,
        maxLength: 24,
        showCounter: false,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        textStyle: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
        onChanged: context.read<OnboardingCubit>().updateName,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

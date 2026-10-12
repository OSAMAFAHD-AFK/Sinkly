import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../manager/onboarding_cubit.dart';
import 'commitment_heart_scene_widget.dart';
import 'hold_to_commit_button_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 12 — Personal commitment, sealed with a press-and-hold gesture.
class PersonalCommitmentStepWidget extends StatefulWidget {
  const PersonalCommitmentStepWidget({super.key});

  @override
  State<PersonalCommitmentStepWidget> createState() => _PersonalCommitmentStepWidgetState();
}

class _PersonalCommitmentStepWidgetState extends State<PersonalCommitmentStepWidget> {
  bool _celebrate = false;

  /// Live hold progress (0…1) shared with the heart scene — no rebuilds.
  final ValueNotifier<double> _holdProgress = ValueNotifier(0);

  @override
  void dispose() {
    _holdProgress.dispose();
    super.dispose();
  }

  Future<void> _onCommitted() async {
    final cubit = context.read<OnboardingCubit>()..confirmCommitment();
    setState(() => _celebrate = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) cubit.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select((OnboardingCubit c) => c.state.preferences.trimmedName);
    final alreadyCommitted = context.select((OnboardingCubit c) => c.state.preferences.commitmentConfirmed);
    final isRevisit = alreadyCommitted && !_celebrate;

    return Stack(
      children: [
        OnboardingStepScaffoldWidget(
          illustration: CommitmentHeartSceneWidget(holdProgress: _holdProgress, committed: _celebrate || isRevisit),
          title: context.tr('commitment_title', {'name': name}),
          highlight: name,
          // Revisiting the step: the commitment is already sealed → plain CTA.
          ctaLabel: context.tr('continue'),
          onCtaPressed: isRevisit ? context.read<OnboardingCubit>().nextStep : null,
          customCta: isRevisit
              ? null
              : HoldToCommitButtonWidget(
                  label: context.tr('commitment_cta'),
                  hint: context.tr('commitment_hold_hint'),
                  completedLabel: context.tr('commitment_done'),
                  onCommitted: _onCommitted,
                  onProgressChanged: (value) => _holdProgress.value = value,
                ),
          body: Column(
            children: [
              CustomCardContainer(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“',
                      style: AppTextStyles.display.copyWith(color: AppColors.primary, fontSize: 48, height: 0.8),
                    ),
                    Text(
                      context.tr('commitment_quote'),
                      style: AppTextStyles.title.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text('— $name', style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_celebrate) const Positioned.fill(child: ConfettiBurstWidget()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../manager/sink_unlock_cubit.dart';
import 'sprint_duration_picker_widget.dart';

/// Stage 1 — what's locked, the 3-step game plan and the "start" CTA.
class SinkUnlockIntroStageWidget extends StatelessWidget {
  const SinkUnlockIntroStageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SinkUnlockCubit>();
    final state = context.watch<SinkUnlockCubit>().state;
    final isLocked = state.lockStatus.isLocked;
    final duration = context.minutes(state.sprintMinutes);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
            children: [
              Center(
                child: GlassIconOrbWidget(
                  icon: isLocked ? Icons.lock_rounded : Icons.cleaning_services_rounded,
                  size: 100,
                  iconColor: isLocked ? AppColors.ink : AppColors.primaryInk,
                ),
              ),
              Text(
                context.tr(isLocked ? 'unlock_intro_title_locked' : 'unlock_intro_title_free'),
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr('unlock_intro_subtitle', {'duration': duration}),
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.blockedApps.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final app in state.blockedApps)
                      BlockableAppIconWidget(app: app, size: 46, showLockBadge: isLocked),
                  ],
                ).animate().fadeIn(delay: 150.ms).scaleXY(begin: 0.9, curve: Curves.easeOutBack),
              const SizedBox(height: AppSpacing.lg),
              CustomCardContainer(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    _PlanStepRow(
                      number: 1,
                      emoji: '⏱️',
                      text: context.tr('unlock_plan_step_timer', {'duration': duration}),
                    ),
                    const Divider(height: 1),
                    _PlanStepRow(number: 2, emoji: '🧽', text: context.tr('unlock_plan_step_clean')),
                    const Divider(height: 1),
                    _PlanStepRow(number: 3, emoji: '📸', text: context.tr('unlock_plan_step_photo')),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.xs,
            AppSpacing.screenGutter,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              // Next to the main action so it is always reachable (no scrolling).
              const SprintDurationButtonWidget().animate().fadeIn(delay: 350.ms),
              const SizedBox(height: AppSpacing.sm),
              CustomPrimaryButton(
                label: context.tr('unlock_start_sprint_cta', {'duration': duration}),
                icon: Icons.play_arrow_rounded,
                showShimmer: true,
                onPressed: cubit.startSprint,
              ),
              TextButton(
                onPressed: state.isCapturing ? null : cubit.captureAndVerifyPhoto,
                child: Text(
                  context.tr('unlock_already_clean'),
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.number, required this.emoji, required this.text});

  final int number;
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Text('$number', style: AppTextStyles.label.copyWith(color: AppColors.primaryInk, letterSpacing: 0)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14))),
        ],
      ),
    );
  }
}

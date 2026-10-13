import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../manager/onboarding_cubit.dart';
import 'analysis_progress_checklist_widget.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 13 — "{name}'s Sinkly plan is ready!" after a short build-up.
class PersonalizedPlanSummaryStepWidget extends StatefulWidget {
  const PersonalizedPlanSummaryStepWidget({super.key});

  @override
  State<PersonalizedPlanSummaryStepWidget> createState() => _PersonalizedPlanSummaryStepWidgetState();
}

class _PersonalizedPlanSummaryStepWidgetState extends State<PersonalizedPlanSummaryStepWidget> {
  bool _planReady = false;

  @override
  Widget build(BuildContext context) {
    final preferences = context.select((OnboardingCubit c) => c.state.preferences);
    final name = preferences.trimmedName;
    final plan = preferences.toUserPlan(onboardingCompleted: false);

    final step = OnboardingStepScaffoldWidget(
      title: _planReady ? context.tr('plan_ready_title', {'name': name}) : context.tr('plan_building_title'),
      highlight: name,
      ctaLabel: context.tr('plan_ready_cta'),
      showCtaShimmer: _planReady,
      onCtaPressed: _planReady ? context.read<OnboardingCubit>().nextStep : null,
      body: AnimatedSwitcher(
        duration: AppDurations.slow,
        child: _planReady
            ? _PlanSummaryCard(plan: plan)
            : AnalysisProgressChecklistWidget(
                title: context.tr('plan_building_subtitle'),
                duration: const Duration(milliseconds: 2800),
                items: [
                  context.tr('plan_building_item_schedule'),
                  context.tr('plan_building_item_apps'),
                  context.tr('plan_building_item_reminders'),
                ],
                onCompleted: () {
                  if (!mounted) return;
                  AppFunctions.successHaptic();
                  setState(() => _planReady = true);
                },
              ),
      ),
    );

    // Confetti rains over the plan the moment it is revealed.
    return Stack(
      children: [
        step,
        if (_planReady) const Positioned.fill(child: ConfettiBurstWidget(particleCount: 70)),
      ],
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan});

  final UserPlanModel plan;

  String _daysLabel(BuildContext context) {
    final schedule = plan.schedule;
    final active = schedule.activeWeekdays;
    // No "workdays/weekends" wording: work weeks differ from country to country.
    if (active.length == 7) return context.tr('preset_all_week');
    if (active.length <= 3) {
      return active.map((weekday) => context.tr(AppFunctions.weekdayLongKey(weekday))).join(context.isRtl ? '، ' : ', ');
    }
    return context.tr('plan_days_count', {'count': '${active.length}'});
  }

  String _mealsLabel(BuildContext context) {
    final schedule = plan.schedule;
    if (!schedule.hasActiveDays) return '—';
    if (!schedule.isUniformAcrossActiveDays) {
      return context.tr('plan_meals_custom', {'count': '${schedule.weeklyMealCount}'});
    }
    final meals = schedule.dayPlan(schedule.activeWeekdays.first).meals;
    final times = meals
        .map(
          (meal) =>
              '${context.tr(meal.type.translationKey)} ${AppFunctions.formatMinutesOfDay(context, meal.minutesOfDay)}',
        )
        .join(' · ');
    return '${context.tr('plan_meals_count', {'count': '${meals.length}'})}\n$times';
  }

  @override
  Widget build(BuildContext context) {
    final apps = plan.blockedApps;
    final rows = <Widget>[
      _SummaryRow(emoji: '📅', label: context.tr('plan_row_days'), value: _daysLabel(context)),
      _SummaryRow(emoji: '🍽️', label: context.tr('plan_row_meals'), value: _mealsLabel(context)),
      _SummaryRow(
        emoji: '🔒',
        label: context.tr('plan_row_apps'),
        value: apps.map((app) => app.displayName).join(', '),
        trailing: Wrap(
          spacing: 4,
          children: [for (final app in apps.take(4)) BlockableAppIconWidget(app: app, size: 24)],
        ),
      ),
      _SummaryRow(emoji: '🎁', label: context.tr('plan_row_bonus'), value: context.tr('plan_bonus_value')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // She celebrates the plan with the user.
        const Center(
          child: HeroineCharacterWidget(width: 118, pose: HeroinePose.cheer, motion: HeroineMotion.cheer),
        ),
        // Hero stat: hours reclaimed per week.
        CustomCardContainer(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF2FFFFFF), Color(0xE6E8F6FD)],
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
          child: Column(
            children: [
              Text(context.tr('plan_reclaimed_label'), style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xs),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: plan.estimatedHoursReclaimedPerWeek),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  context.tr('plan_reclaimed_value', {'h': '$value'}),
                  style: AppTextStyles.statNumber.copyWith(color: AppColors.primaryInk),
                ),
              ),
              const SizedBox(height: 2),
              Text(context.tr('plan_reclaimed_caption'), style: AppTextStyles.caption),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
        const SizedBox(height: AppSpacing.md),
        CustomCardContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                rows[i].animate(delay: (150 + i * 120).ms).fadeIn().slideX(begin: context.flipX(0.06)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.emoji, required this.label, required this.value, this.trailing});

  final String emoji;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 10.5)),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
        ],
      ),
    );
  }
}

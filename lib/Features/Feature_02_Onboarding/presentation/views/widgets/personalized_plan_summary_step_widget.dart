import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/app_icons_wrap_widget.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/sinkly_logo_mark_painter.dart';
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
      headerAlign: TextAlign.center,
      title: _planReady ? context.tr('plan_ready_title', {'name': name}) : context.tr('plan_building_title'),
      highlight: name,
      ctaLabel: context.tr('plan_ready_cta'),
      showCtaShimmer: _planReady,
      onCtaPressed: _planReady ? context.read<OnboardingCubit>().nextStep : null,
      body: AnimatedSwitcher(
        duration: AppDurations.slow,
        child: _planReady
            ? _PlanSummaryCard(plan: plan, name: name)
            : AnalysisProgressChecklistWidget(
                title: context.tr('plan_building_subtitle'),
                duration: const Duration(milliseconds: 4800),
                emojis: const ['📅', '🛡️', '📸', '🔒', '🔔'],
                items: [
                  context.tr('plan_building_item_schedule'),
                  context.tr('plan_building_item_apps'),
                  context.tr('plan_building_item_camera'),
                  context.tr('plan_building_item_protection'),
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

/// The reveal: the heroine cheers, a sky card counts up the hours
/// reclaimed, and the plan itself "prints" as a membership ticket.
class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan, required this.name});

  final UserPlanModel plan;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: HeroineCharacterWidget(width: 112, pose: HeroinePose.cheer, motion: HeroineMotion.cheer),
        ),
        _ReclaimedTimeCard(hours: plan.estimatedHoursReclaimedPerWeek)
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 600.ms),
        const SizedBox(height: AppSpacing.md),
        _PlanTicket(plan: plan, name: name)
            .animate(delay: 250.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.12, curve: Curves.easeOutCubic, duration: 600.ms),
      ],
    );
  }
}

/// Sky gradient card: "7 hours every week" counting up, with soft rings.
class _ReclaimedTimeCard extends StatelessWidget {
  const _ReclaimedTimeCard({required this.hours});

  final int hours;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.cardAll,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9FD8F6), Color(0xFF4FA3E0)],
          ),
          borderRadius: AppRadii.cardAll,
          boxShadow: AppShadows.primaryGlow(strength: 0.6),
        ),
        child: Stack(
          children: [
            // Decorative clock rings drifting slowly.
            for (final (index, size) in const [150.0, 220.0].indexed)
              PositionedDirectional(
                end: -size / 3,
                top: -size / 3,
                child:
                    Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 14),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true), delay: (index * 500).ms)
                        .scaleXY(begin: 0.95, end: 1.05, duration: 2400.ms, curve: Curves.easeInOut),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('plan_reclaimed_label'),
                          style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: hours),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Text(
                            context.tr('plan_reclaimed_value', {'h': '$value'}),
                            style: AppTextStyles.statNumber.copyWith(color: Colors.white, fontSize: 36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('plan_reclaimed_caption'),
                          style: AppTextStyles.bodyStrong.copyWith(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plan as a membership ticket: header with the user's name, a
/// perforated tear line, then days · meals · apps · bonus.
class _PlanTicket extends StatelessWidget {
  const _PlanTicket({required this.plan, required this.name});

  final UserPlanModel plan;
  final String name;

  @override
  Widget build(BuildContext context) {
    final schedule = plan.schedule;
    final apps = plan.blockedApps;
    final sections = <Widget>[
      _TicketSection(
        emoji: '📅',
        label: context.tr('plan_row_days'),
        child: _WeekDots(schedule: schedule),
      ),
      _TicketSection(
        emoji: '🍽️',
        label: context.tr('plan_row_meals'),
        child: _MealChips(schedule: schedule),
      ),
      _TicketSection(
        emoji: '🔒',
        label: context.tr('plan_row_apps'),
        child: apps.isEmpty
            ? Text(context.tr('plan_apps_system_picked'), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14))
            : AppIconsWrapWidget(apps: apps, size: 32, maxIcons: 7, spacing: 6),
      ),
      _TicketSection(
        emoji: '🎁',
        label: context.tr('plan_row_bonus'),
        child: Text(context.tr('plan_bonus_value'), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
      ),
    ];

    return CustomCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                const SizedBox.square(dimension: 38, child: CustomPaint(painter: _TicketMarkPainter())),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('plan_ticket_title'), style: AppTextStyles.titleSmall),
                      Text(
                        name.isEmpty ? context.tr('plan_ticket_subtitle_generic') : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryInk, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: const BoxDecoration(color: AppColors.successSoft, borderRadius: AppRadii.pillAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('plan_ticket_ready'),
                        style: AppTextStyles.label.copyWith(color: AppColors.success, letterSpacing: 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _PerforatedDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            child: Column(
              children: [
                for (final (index, section) in sections.indexed)
                  section
                      .animate(delay: (450 + index * 140).ms)
                      .fadeIn(duration: 320.ms)
                      .slideX(begin: context.flipX(0.08), curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  const _TicketSection({required this.emoji, required this.label, required this.child});

  final String emoji;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The week as seven letters; active days are sky-filled.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.schedule});

  final WeeklyLockScheduleModel schedule;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final (index, weekday) in WeeklyLockScheduleModel.weekdays.indexed)
          Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: schedule.dayPlan(weekday).isActive ? AppGradients.primaryButton : null,
                  color: schedule.dayPlan(weekday).isActive ? null : AppColors.divider.withValues(alpha: 0.6),
                ),
                child: Text(
                  context.tr(AppFunctions.weekdayShortKey(weekday)),
                  style: AppTextStyles.label.copyWith(
                    letterSpacing: 0,
                    color: schedule.dayPlan(weekday).isActive ? AppColors.onPrimary : AppColors.inkMuted,
                  ),
                ),
              )
              .animate(delay: (600 + index * 50).ms)
              .scaleXY(begin: 0.4, curve: Curves.easeOutBack, duration: 380.ms)
              .fadeIn(duration: 200.ms),
      ],
    );
  }
}

/// Meals with their lock times as chips (or a "custom per day" line).
class _MealChips extends StatelessWidget {
  const _MealChips({required this.schedule});

  final WeeklyLockScheduleModel schedule;

  static String _emoji(MealType type) => switch (type) {
    MealType.breakfast => '🥐',
    MealType.lunch => '🥗',
    MealType.dinner => '🍝',
  };

  @override
  Widget build(BuildContext context) {
    if (!schedule.hasActiveDays) return Text('—', style: AppTextStyles.bodyStrong);
    if (!schedule.isUniformAcrossActiveDays) {
      return Text(
        context.tr('plan_meals_custom', {'count': '${schedule.weeklyMealCount}'}),
        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
      );
    }
    final meals = schedule.dayPlan(schedule.activeWeekdays.first).meals;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final meal in meals)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.pillAll,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_emoji(meal.type), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '${context.tr(meal.type.translationKey)} · '
                  '${AppFunctions.formatMinutesOfDay(context, meal.minutesOfDay)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ticket tear line: notches on both edges + a dashed line.
class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 20, child: CustomPaint(painter: _PerforationPainter()));
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final notch = Paint()..color = const Color(0xFFEAF4FB);
    canvas
      ..drawCircle(Offset(0, y), 10, notch)
      ..drawCircle(Offset(size.width, y), 10, notch);
    final dash = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 18.0; x < size.width - 18; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small Sinkly mark for the ticket header.
class _TicketMarkPainter extends CustomPainter {
  const _TicketMarkPainter();

  @override
  void paint(Canvas canvas, Size size) => SinklyLogoMarkPainter().paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

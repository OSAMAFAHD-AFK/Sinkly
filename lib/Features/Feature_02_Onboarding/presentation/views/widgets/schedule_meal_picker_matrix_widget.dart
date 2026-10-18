import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/weekly_lock_schedule_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/glass_bottom_sheet.dart';

/// Weekly lock schedule editor (onboarding screen 8, reused by the Plan tab).
/// Purely presentational: data in, edits out through callbacks.
///
/// Two calm cards instead of a form:
///  1. **Days** — seven day capsules, all on by default (work weeks differ
///     per country, so no presets): tap a day to turn it off/on. Each
///     capsule shows its meals as dots.
///  2. **Meals** — Breakfast / Lunch / Dinner toggle chips (any combination),
///     a morning→night ribbon showing exactly when the apps lock, and one
///     row per meal with its time.
/// Plus a live "locks per week" summary. "Different meals on some days"
/// switches meal edits from all days to one chosen day.
class ScheduleMealPickerMatrixWidget extends StatefulWidget {
  const ScheduleMealPickerMatrixWidget({
    super.key,
    required this.schedule,
    required this.onDayToggled,
    required this.onMealToggled,
    required this.onMealTimeChanged,
    required this.onSyncAllDaysWith,
  });

  final WeeklyLockScheduleModel schedule;
  final ValueChanged<int> onDayToggled;
  final void Function(List<int> weekdays, MealType type, bool enabled) onMealToggled;
  final void Function(List<int> weekdays, int mealIndex, int minutesOfDay) onMealTimeChanged;
  final ValueChanged<int> onSyncAllDaysWith;

  @override
  State<ScheduleMealPickerMatrixWidget> createState() => _ScheduleMealPickerMatrixWidgetState();
}

class _ScheduleMealPickerMatrixWidgetState extends State<ScheduleMealPickerMatrixWidget> {
  late bool _customizePerDay = !widget.schedule.isUniformAcrossActiveDays;
  int? _editingWeekday;

  WeeklyLockScheduleModel get _schedule => widget.schedule;

  /// The day whose meals are shown in the meals card.
  int? get _referenceWeekday {
    final active = _schedule.activeWeekdays;
    if (active.isEmpty) return null;
    if (_customizePerDay && _editingWeekday != null && active.contains(_editingWeekday)) return _editingWeekday;
    return active.first;
  }

  /// Days affected by meal edits.
  List<int> get _targetWeekdays {
    final reference = _referenceWeekday;
    if (reference == null) return const [];
    return _customizePerDay ? [reference] : _schedule.activeWeekdays;
  }

  void _setCustomizePerDay(bool value) {
    AppFunctions.selectionHaptic();
    final reference = _referenceWeekday;
    // Back to "same every day": every day copies the day being viewed.
    if (!value && reference != null && !_schedule.isUniformAcrossActiveDays) widget.onSyncAllDaysWith(reference);
    setState(() {
      _customizePerDay = value;
      _editingWeekday = reference;
    });
  }

  Future<void> _pickTime(int mealIndex, MealSlotModel meal) async {
    final picked = await showGlassTimePickerSheet(
      context: context,
      title: context.tr('time_picker_title', {'meal': context.tr(meal.type.translationKey)}),
      initialMinutesOfDay: meal.minutesOfDay,
    );
    if (picked != null) widget.onMealTimeChanged(_targetWeekdays, mealIndex, picked);
  }

  @override
  Widget build(BuildContext context) {
    final reference = _referenceWeekday;
    final referencePlan = reference == null ? null : _schedule.dayPlan(reference);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Days ───────────────────────────────────────────────────────
        _SectionCard(
          icon: Icons.calendar_month_rounded,
          title: context.tr('schedule_section_days'),
          subtitle: context.tr('schedule_days_subtitle'),
          child: _WeekStrip(
            schedule: _schedule,
            highlightedWeekday: _customizePerDay ? reference : null,
            onDayTapped: widget.onDayToggled,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Meals ──────────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
          ),
          child: referencePlan == null
              ? _EmptyDaysHint(key: const ValueKey('empty'), message: context.tr('schedule_pick_one_day'))
              : _SectionCard(
                  key: const ValueKey('meals'),
                  icon: Icons.restaurant_rounded,
                  title: context.tr('schedule_section_meals'),
                  subtitle: context.tr('schedule_meals_subtitle'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Which day is being edited (only in per-day mode).
                      AnimatedSize(
                        duration: AppDurations.medium,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _customizePerDay
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: _DayTabs(
                                  weekdays: _schedule.activeWeekdays,
                                  selected: reference!,
                                  onSelected: (weekday) {
                                    AppFunctions.selectionHaptic();
                                    setState(() => _editingWeekday = weekday);
                                  },
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      _MealChoiceChips(
                        selected: {for (final meal in referencePlan.meals) meal.type},
                        onToggled: (type, enabled) => widget.onMealToggled(_targetWeekdays, type, enabled),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DayRibbon(meals: referencePlan.meals),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedSize(
                        duration: AppDurations.medium,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            for (final (index, meal) in referencePlan.meals.indexed)
                              _MealRow(
                                    key: ValueKey('${reference}_${meal.type.name}'),
                                    meal: meal,
                                    timeLabel: AppFunctions.formatMinutesOfDay(context, meal.minutesOfDay),
                                    isLast: index == referencePlan.meals.length - 1,
                                    onTap: () => _pickTime(index, meal),
                                  )
                                  .animate(key: ValueKey('${reference}_${meal.type.name}_in'))
                                  .fadeIn(duration: 260.ms, delay: (60 * index).ms)
                                  .slideY(begin: 0.25, curve: Curves.easeOutCubic),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CustomizeToggle(value: _customizePerDay, onChanged: _setCustomizePerDay),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (referencePlan != null) _WeeklyLocksSummary(count: _schedule.weeklyMealCount),
      ],
    );
  }
}

// ── Building blocks ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 20, color: AppColors.primaryInk),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Breakfast / Lunch / Dinner toggles — any combination. The last selected
/// meal can't be switched off (it shakes gently instead).
class _MealChoiceChips extends StatefulWidget {
  const _MealChoiceChips({required this.selected, required this.onToggled});

  final Set<MealType> selected;
  final void Function(MealType type, bool enabled) onToggled;

  @override
  State<_MealChoiceChips> createState() => _MealChoiceChipsState();
}

class _MealChoiceChipsState extends State<_MealChoiceChips> {
  MealType? _shaking;
  int _shakeTick = 0;

  void _onTap(MealType type) {
    final isOn = widget.selected.contains(type);
    if (isOn && widget.selected.length == 1) {
      AppFunctions.lightHaptic();
      setState(() {
        _shaking = type;
        _shakeTick++;
      });
      return;
    }
    AppFunctions.selectionHaptic();
    widget.onToggled(type, !isOn);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, type) in MealType.values.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child:
                _MealChip(
                      emoji: _MealRow.emojiFor(type),
                      label: context.tr(type.translationKey),
                      isOn: widget.selected.contains(type),
                      onTap: () => _onTap(type),
                    )
                    .animate(key: ValueKey('${type.name}_$_shakeTick'), autoPlay: _shaking == type && _shakeTick > 0)
                    .shakeX(hz: 6, amount: 4, duration: 380.ms),
          ),
        ],
      ],
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({required this.emoji, required this.label, required this.isOn, required this.onTap});

  final String emoji;
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isOn,
      label: label,
      child: AnimatedPressableWidget(
        onTap: onTap,
        pressedScale: 0.94,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: isOn
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA8DDF8), Color(0xFF5AAFE6)],
                  )
                : null,
            color: isOn ? null : Colors.white,
            borderRadius: AppRadii.mediumAll,
            border: Border.all(color: isOn ? Colors.white : AppColors.divider, width: 1.4),
            boxShadow: isOn ? AppShadows.primaryGlow(strength: 0.4) : const [],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  PositionedDirectional(
                    end: -12,
                    top: -6,
                    child: AnimatedScale(
                      scale: isOn ? 1 : 0,
                      duration: AppDurations.fast,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: const Icon(Icons.check_rounded, size: 11, color: AppColors.primaryInk),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 13.5,
                    color: isOn ? Colors.white : AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seven tall day capsules; active ones are sky-filled and show one dot per
/// meal, so the whole week reads at a glance.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.schedule, required this.highlightedWeekday, required this.onDayTapped});

  final WeeklyLockScheduleModel schedule;
  final int? highlightedWeekday;
  final ValueChanged<int> onDayTapped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final width = ((constraints.maxWidth - gap * 6) / 7).clamp(30.0, 52.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final weekday in WeeklyLockScheduleModel.weekdays)
              _DayCapsule(
                width: width,
                label: context.tr(AppFunctions.weekdayShortKey(weekday)),
                semanticLabel: context.tr(AppFunctions.weekdayLongKey(weekday)),
                plan: schedule.dayPlan(weekday),
                isHighlighted: weekday == highlightedWeekday,
                onTap: () {
                  AppFunctions.selectionHaptic();
                  onDayTapped(weekday);
                },
              ),
          ],
        );
      },
    );
  }
}

class _DayCapsule extends StatelessWidget {
  const _DayCapsule({
    required this.width,
    required this.label,
    required this.semanticLabel,
    required this.plan,
    required this.isHighlighted,
    required this.onTap,
  });

  final double width;
  final String label;
  final String semanticLabel;
  final DayMealPlanModel plan;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = plan.isActive;
    return Semantics(
      button: true,
      toggled: active,
      label: semanticLabel,
      child: AnimatedPressableWidget(
        onTap: onTap,
        pressedScale: 0.9,
        semanticLabel: semanticLabel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: width,
          height: width * 1.45,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA8DDF8), Color(0xFF5AAFE6)],
                  )
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(width / 2),
            border: Border.all(
              color: isHighlighted ? AppColors.ink : (active ? Colors.white : AppColors.divider),
              width: isHighlighted ? 2 : 1.4,
            ),
            boxShadow: active ? AppShadows.primaryGlow(strength: 0.45) : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shrinks in both directions: tall scripts (Hindi) at large
              // text sizes must still fit the fixed-height capsule.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontSize: 14,
                      color: active ? Colors.white : AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // One dot per meal (fades when the day is off).
              AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: AppDurations.fast,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < plan.meals.length; i++)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Active days as chips — picks which day the meals card edits.
class _DayTabs extends StatelessWidget {
  const _DayTabs({required this.weekdays, required this.selected, required this.onSelected});

  final List<int> weekdays;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('schedule_editing_day', {'day': context.tr(AppFunctions.weekdayLongKey(selected))}),
          style: AppTextStyles.caption.copyWith(color: AppColors.primaryInk, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final weekday in weekdays) ...[
                AnimatedPressableWidget(
                  onTap: () => onSelected(weekday),
                  semanticLabel: context.tr(AppFunctions.weekdayLongKey(weekday)),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: weekday == selected ? AppGradients.ink : null,
                      color: weekday == selected ? null : Colors.white,
                      borderRadius: AppRadii.pillAll,
                      border: Border.all(color: weekday == selected ? Colors.transparent : AppColors.divider),
                    ),
                    child: Text(
                      context.tr(AppFunctions.weekdayLongKey(weekday)),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: weekday == selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Morning → night ribbon with a marker at every meal end: shows at a glance
/// *when* the apps lock. Markers glide when a time changes.
class _DayRibbon extends StatelessWidget {
  const _DayRibbon({required this.meals});

  final List<MealSlotModel> meals;

  static const int _startMinutes = 6 * 60;
  static const int _endMinutes = 24 * 60;

  static double _fraction(int minutes) => ((minutes - _startMinutes) / (_endMinutes - _startMinutes)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const marker = 30.0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The day itself.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 8,
                    height: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: AppRadii.pillAll,
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: [Color(0xFFFFE29A), Color(0xFFA7DBF7), Color(0xFF9A93F0), Color(0xFF3D4B7A)],
                          stops: [0, 0.4, 0.75, 1],
                        ),
                      ),
                    ),
                  ),
                  for (final meal in meals)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(meal.type),
                      tween: Tween(end: _fraction(meal.minutesOfDay)),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      builder: (context, fraction, child) => PositionedDirectional(
                        start: (fraction * width - marker / 2).clamp(-4.0, width - marker + 4),
                        top: 0,
                        bottom: 0,
                        width: marker,
                        child: child!,
                      ),
                      child: _RibbonMarker(emoji: _MealRow.emojiFor(meal.type), size: marker)
                          .animate(key: ValueKey('marker_${meal.type.name}'))
                          .scaleXY(begin: 0.3, curve: Curves.easeOutBack, duration: 380.ms)
                          .fadeIn(duration: 200.ms),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.wb_sunny_rounded, size: 14, color: Color(0xFFF2B33D)),
            const SizedBox(width: 4),
            Text(AppFunctions.formatMinutesOfDay(context, _startMinutes), style: AppTextStyles.label),
            Expanded(
              child: Text(
                context.tr('schedule_ribbon_hint'),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTextStyles.caption.copyWith(fontSize: 11.5),
              ),
            ),
            Text(AppFunctions.formatMinutesOfDay(context, 0), style: AppTextStyles.label),
            const SizedBox(width: 4),
            const Icon(Icons.nightlight_round, size: 14, color: Color(0xFF6B6FD8)),
          ],
        ),
      ],
    );
  }
}

class _RibbonMarker extends StatelessWidget {
  const _RibbonMarker({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppShadows.soft),
          child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
        ),
        Expanded(child: Container(width: 2, color: AppColors.inkMuted.withValues(alpha: 0.35))),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.lock_rounded, size: 8, color: Colors.white),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({super.key, required this.meal, required this.timeLabel, required this.isLast, required this.onTap});

  final MealSlotModel meal;
  final String timeLabel;
  final bool isLast;
  final VoidCallback onTap;

  static String emojiFor(MealType type) => switch (type) {
    MealType.breakfast => '🥐',
    MealType.lunch => '🥗',
    MealType.dinner => '🍝',
  };

  @override
  Widget build(BuildContext context) {
    final name = context.tr(meal.type.translationKey);
    return AnimatedPressableWidget(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: '$name, $timeLabel',
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.primarySoft.withValues(alpha: 0.45),
          borderRadius: AppRadii.mediumAll,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(emojiFor(meal.type), style: const TextStyle(fontSize: 21)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyStrong),
                  Text(context.tr('schedule_lock_starts_after'), style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // The time is the button: big, clear, obviously tappable.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.pillAll,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppDurations.fast,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      timeLabel,
                      key: ValueKey(timeLabel),
                      style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.primaryInk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizeToggle extends StatelessWidget {
  const _CustomizeToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: InkWell(
        borderRadius: AppRadii.mediumAll,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 20, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('schedule_customize_each_day'),
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                    ),
                    Text(
                      context.tr('schedule_customize_each_day_hint'),
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// "14 · smart locks per week" — the number rolls when the plan changes.
class _WeeklyLocksSummary extends StatelessWidget {
  const _WeeklyLocksSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xF2FFFFFF), Color(0xE6E8F6FD)]),
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(gradient: AppGradients.ink, shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(end: count.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '${value.round()}',
              style: AppTextStyles.title.copyWith(color: AppColors.primaryInk, fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.tr('schedule_locks_per_week_label'),
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDaysHint extends StatelessWidget {
  const _EmptyDaysHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      fillColor: AppColors.warningSoft.withValues(alpha: 0.85),
      child: Row(
        children: [
          const Text('👆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodyStrong)),
        ],
      ),
    );
  }
}

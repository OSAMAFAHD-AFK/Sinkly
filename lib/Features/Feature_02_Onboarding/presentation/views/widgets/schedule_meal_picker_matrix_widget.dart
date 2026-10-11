import 'package:flutter/material.dart';

import '../../../../../core/models/weekly_lock_schedule_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/glass_bottom_sheet.dart';
import '../../../../../core/widgets/section_header_widget.dart';

/// The unified "days × meals × lock times" matrix (screen 8, reused by the
/// Plan tab). Purely presentational: all data comes in, all edits go out
/// through callbacks, so it works with any cubit.
///
///  1. Days     — preset chips (multi-select) + 7 toggleable day bubbles
///  2. Meals    — 1 / 2 / 3 meals segmented cards
///  3. Times    — meal end-time tiles opening an iOS wheel picker
///  "Customize each day" switches edits from all active days to one day.
class ScheduleMealPickerMatrixWidget extends StatefulWidget {
  const ScheduleMealPickerMatrixWidget({
    super.key,
    required this.schedule,
    required this.onDayToggled,
    required this.onPresetToggled,
    required this.onMealCountChanged,
    required this.onMealTimeChanged,
    required this.onSyncAllDaysWith,
  });

  final WeeklyLockScheduleModel schedule;
  final ValueChanged<int> onDayToggled;
  final ValueChanged<DaySelectionPreset> onPresetToggled;
  final void Function(List<int> weekdays, int mealCount) onMealCountChanged;
  final void Function(List<int> weekdays, int mealIndex, int minutesOfDay) onMealTimeChanged;
  final ValueChanged<int> onSyncAllDaysWith;

  @override
  State<ScheduleMealPickerMatrixWidget> createState() => _ScheduleMealPickerMatrixWidgetState();
}

class _ScheduleMealPickerMatrixWidgetState extends State<ScheduleMealPickerMatrixWidget> {
  late bool _customizePerDay = !widget.schedule.isUniformAcrossActiveDays;
  int? _editingWeekday;

  WeeklyLockScheduleModel get _schedule => widget.schedule;

  /// The day whose meals are displayed in sections 2 & 3.
  int? get _referenceWeekday {
    final active = _schedule.activeWeekdays;
    if (active.isEmpty) return null;
    if (_customizePerDay && _editingWeekday != null && active.contains(_editingWeekday)) return _editingWeekday;
    return active.first;
  }

  /// Days affected by edits in sections 2 & 3.
  List<int> get _targetWeekdays {
    final reference = _referenceWeekday;
    if (reference == null) return const [];
    return _customizePerDay ? [reference] : _schedule.activeWeekdays;
  }

  void _setCustomizePerDay(bool value) {
    AppFunctions.selectionHaptic();
    final reference = _referenceWeekday;
    // Leaving per-day mode: make all days match the day being viewed.
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
        // ── 1. Days ────────────────────────────────────────────────────
        SectionHeaderWidget(title: context.tr('schedule_section_days'), leadingNumber: 1),
        CustomCardContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final preset in DaySelectionPreset.values) ...[
                      _PresetChip(
                        label: context.tr(preset.translationKey),
                        isSelected: _schedule.isPresetSelected(preset),
                        onTap: () => widget.onPresetToggled(preset),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Bubbles shrink on narrow phones (iPhone SE) to avoid overflow.
                  final bubbleSize = ((constraints.maxWidth - 6 * 4) / 7).clamp(30.0, 42.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final weekday in WeeklyLockScheduleModel.weekdays)
                        _DayBubble(
                          size: bubbleSize,
                          label: context.tr(AppFunctions.weekdayShortKey(weekday)),
                          isActive: _schedule.dayPlan(weekday).isActive,
                          onTap: () => widget.onDayToggled(weekday),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (referencePlan == null)
          _EmptyDaysHint(message: context.tr('schedule_pick_one_day'))
        else ...[
          // Per-day customization toggle + day tabs.
          _CustomizeEachDayRow(value: _customizePerDay, onChanged: _setCustomizePerDay),
          AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _customizePerDay
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final weekday in _schedule.activeWeekdays) ...[
                            _PresetChip(
                              label: context.tr(AppFunctions.weekdayLongKey(weekday)),
                              isSelected: weekday == reference,
                              onTap: () => setState(() => _editingWeekday = weekday),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 2. Meals per day ─────────────────────────────────────────
          SectionHeaderWidget(title: context.tr('schedule_section_meals'), leadingNumber: 2),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: AppSpacing.sm),
            child: Text(context.tr('schedule_meals_question'), style: AppTextStyles.caption),
          ),
          Row(
            children: [
              for (final count in const [1, 2, 3]) ...[
                Expanded(
                  child: _MealCountCard(
                    count: count,
                    emoji: switch (count) {
                      1 => '🍲',
                      2 => '🥐',
                      _ => '🍳',
                    },
                    label: context.tr('schedule_meal_count_$count'),
                    isSelected: referencePlan.meals.length == count,
                    onTap: () => widget.onMealCountChanged(_targetWeekdays, count),
                  ),
                ),
                if (count != 3) const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 3. Lock times ────────────────────────────────────────────
          SectionHeaderWidget(title: context.tr('schedule_section_times'), leadingNumber: 3),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: AppSpacing.sm),
            child: Text(context.tr('schedule_times_question'), style: AppTextStyles.caption),
          ),
          CustomCardContainer(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final (index, meal) in referencePlan.meals.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _MealTimeRow(
                    meal: meal,
                    timeLabel: AppFunctions.formatMinutesOfDay(context, meal.minutesOfDay),
                    onTap: () => _pickTime(index, meal),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WeeklyLocksSummary(text: context.tr('schedule_weekly_locks', {'count': '${_schedule.weeklyMealCount}'})),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.ink : null,
          color: isSelected ? null : Colors.white,
          borderRadius: AppRadii.pillAll,
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.divider),
          boxShadow: isSelected ? AppShadows.soft : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  const _DayBubble({required this.size, required this.label, required this.isActive, required this.onTap});

  final double size;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      pressedScale: 0.88,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive ? AppGradients.primaryButton : null,
          color: isActive ? null : Colors.white,
          border: Border.all(color: isActive ? Colors.white : AppColors.divider, width: 1.5),
          boxShadow: isActive ? AppShadows.primaryGlow(strength: 0.55) : const [],
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isActive ? AppColors.onPrimary : AppColors.inkMuted,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CustomizeEachDayRow extends StatelessWidget {
  const _CustomizeEachDayRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, 6, 8, 6),
      borderRadius: AppRadii.pillAll,
      shadows: AppShadows.soft,
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryInk),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('schedule_customize_each_day'), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
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
    );
  }
}

class _MealCountCard extends StatelessWidget {
  const _MealCountCard({
    required this.count,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int count;
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.glassFillStrong,
          borderRadius: AppRadii.mediumAll,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: isSelected ? 1.8 : 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ]
              : AppShadows.soft,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: AppTextStyles.title.copyWith(color: isSelected ? AppColors.primaryInk : AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTimeRow extends StatelessWidget {
  const _MealTimeRow({required this.meal, required this.timeLabel, required this.onTap});

  final MealSlotModel meal;
  final String timeLabel;
  final VoidCallback onTap;

  static String _emojiFor(MealType type) => switch (type) {
    MealType.breakfast => '🥐',
    MealType.lunch => '🥗',
    MealType.dinner => '🍝',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: context.tr(meal.type.translationKey),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(_emojiFor(meal.type), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(meal.type.translationKey), style: AppTextStyles.bodyStrong),
                  Text(context.tr('schedule_lock_starts_after'), style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.pillAll,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.primaryInk),
                  const SizedBox(width: 6),
                  Text(timeLabel, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyLocksSummary extends StatelessWidget {
  const _WeeklyLocksSummary({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: AppRadii.pillAll,
            boxShadow: AppShadows.soft,
          ),
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EmptyDaysHint extends StatelessWidget {
  const _EmptyDaysHint({required this.message});

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

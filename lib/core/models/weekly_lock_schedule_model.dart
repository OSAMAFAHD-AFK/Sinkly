import 'package:equatable/equatable.dart';

/// Meal kinds. The [defaultMinutesOfDay] is when the meal usually *ends*,
/// which is the moment Sinkly locks distracting apps.
enum MealType {
  breakfast(defaultMinutesOfDay: 9 * 60 + 30, translationKey: 'meal_breakfast'),
  lunch(defaultMinutesOfDay: 15 * 60, translationKey: 'meal_lunch'),
  dinner(defaultMinutesOfDay: 21 * 60, translationKey: 'meal_dinner');

  const MealType({required this.defaultMinutesOfDay, required this.translationKey});

  final int defaultMinutesOfDay;
  final String translationKey;

  static MealType fromName(String? name) =>
      MealType.values.firstWhere((type) => type.name == name, orElse: () => MealType.dinner);

  /// Meal templates for "how many meals do you eat at home" answers.
  static List<MealType> templateForCount(int count) => switch (count) {
    <= 1 => const [MealType.dinner],
    2 => const [MealType.breakfast, MealType.dinner],
    _ => const [MealType.breakfast, MealType.lunch, MealType.dinner],
  };
}

/// Quick multi-select day shortcuts on the schedule screen.
enum DaySelectionPreset {
  allWeek(weekdays: [1, 2, 3, 4, 5, 6, 7], translationKey: 'preset_all_week'),
  workdays(weekdays: [1, 2, 3, 4, 5], translationKey: 'preset_workdays'),
  weekends(weekdays: [6, 7], translationKey: 'preset_weekends');

  const DaySelectionPreset({required this.weekdays, required this.translationKey});

  /// ISO weekdays (Mon = 1 … Sun = 7), matching `DateTime.weekday`.
  final List<int> weekdays;
  final String translationKey;
}

/// A single meal whose end time triggers the app lock.
class MealSlotModel extends Equatable {
  const MealSlotModel({required this.type, required this.minutesOfDay});

  final MealType type;

  /// Minutes after midnight (0 … 1439).
  final int minutesOfDay;

  factory MealSlotModel.defaultFor(MealType type) => MealSlotModel(type: type, minutesOfDay: type.defaultMinutesOfDay);

  MealSlotModel copyWith({MealType? type, int? minutesOfDay}) =>
      MealSlotModel(type: type ?? this.type, minutesOfDay: minutesOfDay ?? this.minutesOfDay);

  factory MealSlotModel.fromJson(Map<String, dynamic> json) => MealSlotModel(
    type: MealType.fromName(json['type'] as String?),
    minutesOfDay: (json['minutesOfDay'] as num?)?.toInt() ?? MealType.dinner.defaultMinutesOfDay,
  );

  Map<String, dynamic> toJson() => {'type': type.name, 'minutesOfDay': minutesOfDay};

  @override
  List<Object?> get props => [type, minutesOfDay];
}

/// Meals planned for one weekday.
class DayMealPlanModel extends Equatable {
  const DayMealPlanModel({required this.isActive, required this.meals});

  final bool isActive;
  final List<MealSlotModel> meals;

  factory DayMealPlanModel.withMealCount(int count, {bool isActive = true}) => DayMealPlanModel(
    isActive: isActive,
    meals: MealType.templateForCount(count).map(MealSlotModel.defaultFor).toList(growable: false),
  );

  DayMealPlanModel copyWith({bool? isActive, List<MealSlotModel>? meals}) =>
      DayMealPlanModel(isActive: isActive ?? this.isActive, meals: meals ?? this.meals);

  /// Changes the number of meals while keeping already customized times.
  DayMealPlanModel withMealCount(int count) {
    final template = MealType.templateForCount(count);
    final updated = template
        .map((type) {
          final existing = meals.where((meal) => meal.type == type);
          return existing.isNotEmpty ? existing.first : MealSlotModel.defaultFor(type);
        })
        .toList(growable: false);
    return copyWith(meals: updated);
  }

  DayMealPlanModel withMealTime(int mealIndex, int minutesOfDay) {
    if (mealIndex < 0 || mealIndex >= meals.length) return this;
    final updated = [...meals];
    updated[mealIndex] = updated[mealIndex].copyWith(minutesOfDay: minutesOfDay);
    return copyWith(meals: List.unmodifiable(updated));
  }

  factory DayMealPlanModel.fromJson(Map<String, dynamic> json) => DayMealPlanModel(
    isActive: json['isActive'] as bool? ?? false,
    meals: ((json['meals'] as List?) ?? const [])
        .map((meal) => MealSlotModel.fromJson(Map<String, dynamic>.from(meal as Map)))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {'isActive': isActive, 'meals': meals.map((meal) => meal.toJson()).toList()};

  @override
  List<Object?> get props => [isActive, meals];
}

/// The full weekly blocking schedule (Mon … Sun).
/// All mutation helpers return a new immutable instance so cubits can emit
/// them directly and widgets rebuild only when something really changed.
class WeeklyLockScheduleModel extends Equatable {
  const WeeklyLockScheduleModel({required this.days});

  /// Key = ISO weekday (1 = Monday … 7 = Sunday).
  final Map<int, DayMealPlanModel> days;

  static const List<int> weekdays = [1, 2, 3, 4, 5, 6, 7];

  factory WeeklyLockScheduleModel.initial() =>
      WeeklyLockScheduleModel(days: {for (final weekday in weekdays) weekday: DayMealPlanModel.withMealCount(2)});

  DayMealPlanModel dayPlan(int weekday) => days[weekday] ?? DayMealPlanModel.withMealCount(2, isActive: false);

  List<int> get activeWeekdays => weekdays.where((weekday) => dayPlan(weekday).isActive).toList(growable: false);

  bool get hasActiveDays => activeWeekdays.isNotEmpty;

  int get weeklyMealCount => activeWeekdays.fold(0, (sum, weekday) => sum + dayPlan(weekday).meals.length);

  /// True when every active day shares the exact same meals & times.
  bool get isUniformAcrossActiveDays {
    final active = activeWeekdays;
    if (active.length < 2) return true;
    final reference = dayPlan(active.first).meals;
    return active.every((weekday) => _listEquals(dayPlan(weekday).meals, reference));
  }

  bool isPresetSelected(DaySelectionPreset preset) => preset.weekdays.every((weekday) => dayPlan(weekday).isActive);

  WeeklyLockScheduleModel toggleDay(int weekday) {
    final current = dayPlan(weekday);
    // A newly added day inherits the meals of the other days (consistent week).
    final template = !current.isActive && hasActiveDays ? dayPlan(activeWeekdays.first).meals : null;
    return _replace({weekday: current.copyWith(isActive: !current.isActive, meals: template)});
  }

  /// Multi-select preset behaviour: tapping a selected preset clears its days,
  /// tapping an unselected one activates them (Workdays + Weekends = All week).
  WeeklyLockScheduleModel togglePreset(DaySelectionPreset preset) {
    final activate = !isPresetSelected(preset);
    // New days inherit the meals of an existing active day for consistency.
    final template = hasActiveDays ? dayPlan(activeWeekdays.first).meals : null;
    return _replace({
      for (final weekday in preset.weekdays)
        weekday: dayPlan(weekday).copyWith(
          isActive: activate,
          meals: activate && template != null && !dayPlan(weekday).isActive ? template : null,
        ),
    });
  }

  WeeklyLockScheduleModel withMealCount(Iterable<int> targetWeekdays, int count) =>
      _replace({for (final weekday in targetWeekdays) weekday: dayPlan(weekday).withMealCount(count)});

  WeeklyLockScheduleModel withMealTime(Iterable<int> targetWeekdays, int mealIndex, int minutesOfDay) =>
      _replace({for (final weekday in targetWeekdays) weekday: dayPlan(weekday).withMealTime(mealIndex, minutesOfDay)});

  /// Copies one day's meals onto every other active day.
  WeeklyLockScheduleModel syncAllActiveDaysWith(int sourceWeekday) {
    final meals = dayPlan(sourceWeekday).meals;
    return _replace({for (final weekday in activeWeekdays) weekday: dayPlan(weekday).copyWith(meals: meals)});
  }

  /// Every moment a meal ends (= lock trigger) inside [from, to].
  List<({DateTime at, MealType meal})> lockTriggersBetween(DateTime from, DateTime to) {
    final triggers = <({DateTime at, MealType meal})>[];
    var cursor = DateTime(from.year, from.month, from.day);
    while (!cursor.isAfter(to)) {
      final plan = dayPlan(cursor.weekday);
      if (plan.isActive) {
        for (final meal in plan.meals) {
          final at = cursor.add(Duration(minutes: meal.minutesOfDay));
          if (!at.isBefore(from) && !at.isAfter(to)) triggers.add((at: at, meal: meal.type));
        }
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    triggers.sort((a, b) => a.at.compareTo(b.at));
    return triggers;
  }

  WeeklyLockScheduleModel _replace(Map<int, DayMealPlanModel> changes) =>
      WeeklyLockScheduleModel(days: Map.unmodifiable({...days, ...changes}));

  factory WeeklyLockScheduleModel.fromJson(Map<String, dynamic> json) {
    final initial = WeeklyLockScheduleModel.initial();
    return WeeklyLockScheduleModel(
      days: Map.unmodifiable({
        for (final weekday in weekdays)
          weekday: json['$weekday'] is Map
              ? DayMealPlanModel.fromJson(Map<String, dynamic>.from(json['$weekday'] as Map))
              : initial.dayPlan(weekday),
      }),
    );
  }

  Map<String, dynamic> toJson() => {for (final entry in days.entries) '${entry.key}': entry.value.toJson()};

  static bool _listEquals(List<MealSlotModel> a, List<MealSlotModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [for (final weekday in weekdays) dayPlan(weekday)];
}

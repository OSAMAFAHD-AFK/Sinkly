import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/core/models/shared_core_models.dart';

/// The Dart side of the shared lock-rule cases (Kotlin: LockEngineTest,
/// Swift: SinklyLockEngineTests read the same file).
void main() {
  final file = jsonDecode(File('test/fixtures/lock_engine_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final cases = (file['cases'] as List).cast<Map<String, dynamic>>();

  DateTime? at(Object? value) => value == null ? null : DateTime.parse(value as String);

  UserPlanModel planFor(Map<String, dynamic> testCase) {
    final days = (testCase['days'] as Map<String, dynamic>).map(
      (weekday, minutes) => MapEntry(int.parse(weekday), (minutes as List).cast<int>()),
    );
    final schedule = WeeklyLockScheduleModel(
      days: {
        for (final weekday in WeeklyLockScheduleModel.weekdays)
          weekday: DayMealPlanModel(
            isActive: days.containsKey(weekday),
            meals: [
              for (final (index, minutes) in (days[weekday] ?? const <int>[]).indexed)
                MealSlotModel(type: MealType.values[index.clamp(0, 2)], minutesOfDay: minutes),
            ],
          ),
      },
    );
    return UserPlanModel.initial().copyWith(
      schedule: schedule,
      lockingActiveSince: at(testCase['activeSince']),
      manualLockTriggeredAt: at(testCase['manualLockAt']),
    );
  }

  for (final testCase in cases) {
    test(testCase['name'], () {
      final lastClean = at(testCase['lastCleanAt']);
      final sessions = [
        if (lastClean != null) SinkCleaningSessionModel(id: 's', startedAt: lastClean, completedAt: lastClean),
      ];
      final status = LockStatusModel.evaluate(
        plan: planFor(testCase),
        sessions: sessions,
        now: at(testCase['now'])!,
      );
      final expected = testCase['expect'] as Map<String, dynamic>;
      expect(status.isLocked, expected['locked'], reason: 'locked');
      expect(status.lockedSince, at(expected['lockedSince']), reason: 'lockedSince');
      expect(status.nextLockAt, at(expected['nextLockAt']), reason: 'nextLockAt');
    });
  }

  test('meal times are wall-clock times, built from clock fields', () {
    // Even on a daylight-saving day the meal is at 18:00 on the clock.
    const meal = MealSlotModel(type: MealType.dinner, minutesOfDay: 18 * 60);
    final day = DateTime(2026, 3, 29); // EU clocks move forward on this date.
    final at = meal.on(day);
    expect([at.hour, at.minute, at.day], [18, 0, 29]);
  });
}

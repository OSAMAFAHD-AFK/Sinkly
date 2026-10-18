import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/core/models/shared_core_models.dart';

void main() {
  group('WeeklyLockScheduleModel', () {
    test('presets toggle as multi-select (workdays + weekends = all week)', () {
      var schedule = WeeklyLockScheduleModel.initial();
      expect(schedule.isPresetSelected(DaySelectionPreset.allWeek), isTrue);

      schedule = schedule.togglePreset(DaySelectionPreset.allWeek);
      expect(schedule.hasActiveDays, isFalse);

      schedule = schedule.togglePreset(DaySelectionPreset.workdays);
      expect(schedule.activeWeekdays, [1, 2, 3, 4, 5]);
      expect(schedule.isPresetSelected(DaySelectionPreset.allWeek), isFalse);

      schedule = schedule.togglePreset(DaySelectionPreset.weekends);
      expect(schedule.isPresetSelected(DaySelectionPreset.allWeek), isTrue);
    });

    test('meal count keeps customized times', () {
      var schedule = WeeklyLockScheduleModel.initial().withMealTime([1], 1, 22 * 60); // dinner 22:00 on Monday
      schedule = schedule.withMealCount([1], 3);
      final monday = schedule.dayPlan(1).meals;
      expect(monday.map((m) => m.type), [MealType.breakfast, MealType.lunch, MealType.dinner]);
      expect(monday.last.minutesOfDay, 22 * 60);
      expect(schedule.isUniformAcrossActiveDays, isFalse);
      expect(schedule.syncAllActiveDaysWith(1).isUniformAcrossActiveDays, isTrue);
    });

    test('json round-trip', () {
      final schedule = WeeklyLockScheduleModel.initial().toggleDay(3).withMealCount([1], 1);
      expect(WeeklyLockScheduleModel.fromJson(schedule.toJson()), schedule);
    });
  });

  group('LockStatusModel', () {
    // 2026-10-12 is a Monday. Default plan: breakfast 9:30, dinner 21:00 every day.
    // Locking has been active (onboarding + subscription) since October 1st.
    final plan = UserPlanModel.initial().copyWith(lockingActiveSince: DateTime(2026, 10, 1));

    test('locked after a meal ends until a clean session is recorded', () {
      final now = DateTime(2026, 10, 12, 21, 30);
      final locked = LockStatusModel.evaluate(plan: plan, sessions: const [], now: now);
      expect(locked.isLocked, isTrue);
      expect(locked.lockingMeal, MealType.dinner);

      final cleaned = SinkCleaningSessionModel(
        id: 's1',
        startedAt: DateTime(2026, 10, 12, 21, 10),
        completedAt: DateTime(2026, 10, 12, 21, 14),
      );
      final unlocked = LockStatusModel.evaluate(plan: plan, sessions: [cleaned], now: now);
      expect(unlocked.isLocked, isFalse);
      expect(unlocked.nextLockAt, DateTime(2026, 10, 13, 9, 30));
    });

    test('manual test lock behaves like a meal ending', () {
      final now = DateTime(2026, 10, 12, 12);
      final cleaned = SinkCleaningSessionModel(
        id: 's1',
        startedAt: DateTime(2026, 10, 12, 10),
        completedAt: DateTime(2026, 10, 12, 10, 4),
      );
      final manual = plan.copyWith(manualLockTriggeredAt: DateTime(2026, 10, 12, 11, 59));
      final status = LockStatusModel.evaluate(plan: manual, sessions: [cleaned], now: now);
      expect(status.isLocked, isTrue);
      expect(status.lockingMeal, isNull);
    });
  });

  group('SinkProgressStatsModel', () {
    SinkCleaningSessionModel sessionOn(int day, {int hour = 21}) => SinkCleaningSessionModel(
      id: '$day-$hour',
      startedAt: DateTime(2026, 10, day, hour),
      completedAt: DateTime(2026, 10, day, hour, 3),
    );

    test('current & best streaks', () {
      final sessions = [
        sessionOn(5),
        sessionOn(6),
        sessionOn(7),
        sessionOn(10),
        sessionOn(11),
        sessionOn(11, hour: 10),
      ];
      final stats = SinkProgressStatsModel.fromSessions(sessions, now: DateTime(2026, 10, 12, 8));
      expect(stats.currentStreakDays, 2); // 10th & 11th (today has no clean yet)
      expect(stats.bestStreakDays, 3); // 5th–7th
      expect(stats.totalCleans, 6);
      expect(stats.cleansPerDayLast7.last, 0);
      expect(stats.averageCleaningDuration, const Duration(minutes: 3));
    });
  });
}

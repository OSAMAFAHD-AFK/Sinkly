import 'package:equatable/equatable.dart';

import 'sink_cleaning_session_model.dart';
import 'user_plan_model.dart';
import 'weekly_lock_schedule_model.dart';

/// Pure, side-effect-free evaluation of "are the apps locked right now?".
/// Shared by Home, Sink Unlock and (later) the native background scheduler.
class LockStatusModel extends Equatable {
  const LockStatusModel({
    required this.isLocked,
    this.lockedSince,
    this.lockingMeal,
    this.nextLockAt,
    this.nextLockMeal,
  });

  final bool isLocked;
  final DateTime? lockedSince;

  /// Null while locked means the lock was triggered manually ("Test lock").
  final MealType? lockingMeal;

  final DateTime? nextLockAt;
  final MealType? nextLockMeal;

  /// A meal lock stays pending for this long if the sink is never cleaned.
  static const Duration pendingLockWindow = Duration(hours: 18);

  static LockStatusModel evaluate({
    required UserPlanModel plan,
    required List<SinkCleaningSessionModel> sessions,
    required DateTime now,
  }) {
    final schedule = plan.schedule;
    final pastTriggers = schedule.lockTriggersBetween(now.subtract(pendingLockWindow), now);

    DateTime? latestTriggerAt = pastTriggers.isEmpty ? null : pastTriggers.last.at;
    MealType? latestMeal = pastTriggers.isEmpty ? null : pastTriggers.last.meal;

    final manual = plan.manualLockTriggeredAt;
    if (manual != null && !manual.isAfter(now) && (latestTriggerAt == null || manual.isAfter(latestTriggerAt))) {
      latestTriggerAt = manual;
      latestMeal = null;
    }

    final lastCleanAt = sessions.isEmpty
        ? null
        : sessions.map((session) => session.completedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    final isLocked = latestTriggerAt != null && (lastCleanAt == null || lastCleanAt.isBefore(latestTriggerAt));

    final upcoming = schedule.lockTriggersBetween(
      now.add(const Duration(seconds: 1)),
      now.add(const Duration(days: 8)),
    );

    return LockStatusModel(
      isLocked: isLocked,
      lockedSince: isLocked ? latestTriggerAt : null,
      lockingMeal: isLocked ? latestMeal : null,
      nextLockAt: upcoming.isEmpty ? null : upcoming.first.at,
      nextLockMeal: upcoming.isEmpty ? null : upcoming.first.meal,
    );
  }

  @override
  List<Object?> get props => [isLocked, lockedSince, lockingMeal, nextLockAt, nextLockMeal];
}

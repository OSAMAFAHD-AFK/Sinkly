import 'package:equatable/equatable.dart';

import 'sink_cleaning_session_model.dart';
import 'user_plan_model.dart';
import 'weekly_lock_schedule_model.dart';

/// Pure, side-effect-free evaluation of "are the apps locked right now?".
///
/// THE lock rule of Sinkly. The native blockers (Kotlin `LockEngine`, Swift
/// `SinklyLockEngine`) implement exactly the same rule and are checked
/// against the same cases (`test/fixtures/lock_engine_vectors.json`):
///
///  * A lock starts when a planned meal ends (or a stored manual lock).
///  * It lasts until a clean-sink photo is accepted — there is no expiry.
///  * Only meals that end after locking became active count
///    ([UserPlanModel.lockingActiveSince]: onboarding done + subscribed).
///  * The plan can be edited at any time, even while locked: the rule simply
///    re-reads the current plan, so removing today's meal lifts its lock.
///  * Times are the phone's own wall clock (whatever time zone it is in).
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

  /// Null while locked means a manual lock (no meal).
  final MealType? lockingMeal;

  final DateTime? nextLockAt;
  final MealType? nextLockMeal;

  /// The plan repeats every week, so the latest meal that already ended is
  /// always within the last 7 days (8 for safety around midnight).
  static const Duration lookBack = Duration(days: 8);

  static LockStatusModel evaluate({
    required UserPlanModel plan,
    required List<SinkCleaningSessionModel> sessions,
    required DateTime now,
  }) {
    final schedule = plan.schedule;
    final pastTriggers = schedule.lockTriggersBetween(now.subtract(lookBack), now);

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

    final activeSince = plan.lockingActiveSince;
    // Locks only count after the later of "locking started" and "last clean".
    final anchor = activeSince == null
        ? null
        : (lastCleanAt != null && lastCleanAt.isAfter(activeSince) ? lastCleanAt : activeSince);

    final isLocked = anchor != null && latestTriggerAt != null && latestTriggerAt.isAfter(anchor);

    final upcoming = schedule.lockTriggersBetween(now.add(const Duration(seconds: 1)), now.add(lookBack));

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

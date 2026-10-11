import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

/// Unsaved edits on the Plan tab (schedule + locked apps).
class LockScheduleDraftModel extends Equatable {
  const LockScheduleDraftModel({required this.schedule, required this.blockedAppIds});

  final WeeklyLockScheduleModel schedule;
  final List<String> blockedAppIds;

  factory LockScheduleDraftModel.fromPlan(UserPlanModel plan) =>
      LockScheduleDraftModel(schedule: plan.schedule, blockedAppIds: plan.blockedAppIds);

  bool differsFrom(UserPlanModel plan) => schedule != plan.schedule || !_sameIds(blockedAppIds, plan.blockedAppIds);

  bool get isValid => schedule.hasActiveDays && blockedAppIds.isNotEmpty;

  LockScheduleDraftModel copyWith({WeeklyLockScheduleModel? schedule, List<String>? blockedAppIds}) =>
      LockScheduleDraftModel(schedule: schedule ?? this.schedule, blockedAppIds: blockedAppIds ?? this.blockedAppIds);

  static bool _sameIds(List<String> a, List<String> b) => a.length == b.length && a.toSet().containsAll(b);

  @override
  List<Object?> get props => [schedule, blockedAppIds];
}

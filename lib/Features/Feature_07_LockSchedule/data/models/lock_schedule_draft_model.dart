import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

/// Unsaved edits on the Plan tab (schedule + locked apps / categories).
class LockScheduleDraftModel extends Equatable {
  const LockScheduleDraftModel({required this.schedule, required this.appSelection});

  final WeeklyLockScheduleModel schedule;
  final AppSelectionModel appSelection;

  List<String> get blockedAppIds => appSelection.appIds;

  factory LockScheduleDraftModel.fromPlan(UserPlanModel plan) =>
      LockScheduleDraftModel(schedule: plan.schedule, appSelection: plan.appSelection);

  bool differsFrom(UserPlanModel plan) => schedule != plan.schedule || !_sameSelection(appSelection, plan.appSelection);

  bool get isValid => schedule.hasActiveDays && !appSelection.isEmpty;

  LockScheduleDraftModel copyWith({WeeklyLockScheduleModel? schedule, AppSelectionModel? appSelection}) =>
      LockScheduleDraftModel(schedule: schedule ?? this.schedule, appSelection: appSelection ?? this.appSelection);

  static bool _sameSelection(AppSelectionModel a, AppSelectionModel b) =>
      _sameIds(a.appIds, b.appIds) &&
      _sameIds(a.categoryIds, b.categoryIds) &&
      a.systemPickerCount == b.systemPickerCount;

  static bool _sameIds(List<String> a, List<String> b) => a.length == b.length && a.toSet().containsAll(b);

  @override
  List<Object?> get props => [schedule, appSelection];
}

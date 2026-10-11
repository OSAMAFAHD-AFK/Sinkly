part of 'lock_schedule_cubit.dart';

enum LockScheduleSaveStatus { idle, saving, saved, failure }

class LockScheduleState extends Equatable {
  const LockScheduleState({
    required this.savedPlan,
    required this.draft,
    this.saveStatus = LockScheduleSaveStatus.idle,
    this.failureKey,
  });

  final UserPlanModel savedPlan;
  final LockScheduleDraftModel draft;
  final LockScheduleSaveStatus saveStatus;
  final String? failureKey;

  bool get hasUnsavedChanges => draft.differsFrom(savedPlan);

  LockScheduleState copyWith({
    UserPlanModel? savedPlan,
    LockScheduleDraftModel? draft,
    LockScheduleSaveStatus? saveStatus,
    String? failureKey,
  }) => LockScheduleState(
    savedPlan: savedPlan ?? this.savedPlan,
    draft: draft ?? this.draft,
    saveStatus: saveStatus ?? this.saveStatus,
    failureKey: failureKey,
  );

  @override
  List<Object?> get props => [savedPlan, draft, saveStatus, failureKey];
}

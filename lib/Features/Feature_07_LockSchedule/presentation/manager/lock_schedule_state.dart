part of 'lock_schedule_cubit.dart';

enum LockScheduleSaveStatus { idle, saving, saved, failure }

class LockScheduleState extends Equatable {
  const LockScheduleState({
    required this.savedPlan,
    required this.draft,
    this.saveStatus = LockScheduleSaveStatus.idle,
    this.failureKey,
    this.installedApps = const [],
    this.appsLoaded = false,
  });

  final UserPlanModel savedPlan;
  final LockScheduleDraftModel draft;
  final LockScheduleSaveStatus saveStatus;
  final String? failureKey;

  /// Device apps for the category picker (Android).
  final List<BlockableAppModel> installedApps;
  final bool appsLoaded;

  bool get hasUnsavedChanges => draft.differsFrom(savedPlan);

  LockScheduleState copyWith({
    UserPlanModel? savedPlan,
    LockScheduleDraftModel? draft,
    LockScheduleSaveStatus? saveStatus,
    String? failureKey,
    List<BlockableAppModel>? installedApps,
    bool? appsLoaded,
  }) => LockScheduleState(
    savedPlan: savedPlan ?? this.savedPlan,
    draft: draft ?? this.draft,
    saveStatus: saveStatus ?? this.saveStatus,
    failureKey: failureKey,
    installedApps: installedApps ?? this.installedApps,
    appsLoaded: appsLoaded ?? this.appsLoaded,
  );

  @override
  List<Object?> get props => [savedPlan, draft, saveStatus, failureKey, installedApps, appsLoaded];
}

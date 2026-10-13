import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/shared_core_models.dart';
import '../../data/models/lock_schedule_draft_model.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../data/repos/lock_schedule_repo.dart';

part 'lock_schedule_state.dart';

/// Edits the weekly schedule and locked apps as a draft, then saves.
class LockScheduleCubit extends Cubit<LockScheduleState> {
  LockScheduleCubit(this._repo) : super(_initial(_repo)) {
    _planSubscription = _repo.planChanges.listen((plan) {
      // Keep the draft in sync if nothing is being edited.
      final keepDraft = state.hasUnsavedChanges;
      emit(state.copyWith(savedPlan: plan, draft: keepDraft ? state.draft : LockScheduleDraftModel.fromPlan(plan)));
    });
    _loadInstalledApps();
  }

  AppPickerMode get appPickerMode => _repo.appPickerMode;

  Future<void> _loadInstalledApps() async {
    final apps = await _repo.loadInstalledApps();
    if (!isClosed) emit(state.copyWith(installedApps: apps, appsLoaded: true));
  }

  final LockScheduleRepo _repo;
  late final StreamSubscription<UserPlanModel> _planSubscription;

  static LockScheduleState _initial(LockScheduleRepo repo) {
    final plan = repo.loadPlan();
    return LockScheduleState(savedPlan: plan, draft: LockScheduleDraftModel.fromPlan(plan));
  }

  void _updateSchedule(WeeklyLockScheduleModel schedule) => emit(
    state.copyWith(
      draft: state.draft.copyWith(schedule: schedule),
      saveStatus: LockScheduleSaveStatus.idle,
    ),
  );

  void toggleDay(int weekday) => _updateSchedule(state.draft.schedule.toggleDay(weekday));
  void togglePreset(DaySelectionPreset preset) => _updateSchedule(state.draft.schedule.togglePreset(preset));
  void setMealEnabled(List<int> weekdays, MealType type, bool enabled) =>
      _updateSchedule(state.draft.schedule.withMealEnabled(weekdays, type, enabled: enabled));
  void setMealTime(List<int> weekdays, int index, int minutes) =>
      _updateSchedule(state.draft.schedule.withMealTime(weekdays, index, minutes));
  void syncAllDaysWith(int weekday) => _updateSchedule(state.draft.schedule.syncAllActiveDaysWith(weekday));

  void updateAppSelection(AppSelectionModel selection) => emit(
    state.copyWith(
      draft: state.draft.copyWith(appSelection: selection),
      saveStatus: LockScheduleSaveStatus.idle,
    ),
  );

  void discardChanges() => emit(state.copyWith(draft: LockScheduleDraftModel.fromPlan(state.savedPlan)));

  Future<void> save() async {
    emit(state.copyWith(saveStatus: LockScheduleSaveStatus.saving));
    final result = await _repo.savePlan(state.draft);
    result.fold(
      (failure) => emit(state.copyWith(saveStatus: LockScheduleSaveStatus.failure, failureKey: failure.messageKey)),
      (plan) => emit(
        state.copyWith(
          savedPlan: plan,
          draft: LockScheduleDraftModel.fromPlan(plan),
          saveStatus: LockScheduleSaveStatus.saved,
        ),
      ),
    );
  }

  Future<bool> triggerTestLockNow() async => (await _repo.triggerTestLockNow()).isRight();

  @override
  Future<void> close() async {
    await _planSubscription.cancel();
    return super.close();
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../data_sources/lock_schedule_local_data_source.dart';
import '../models/lock_schedule_draft_model.dart';
import 'lock_schedule_repo.dart';

class LockScheduleRepoImpl implements LockScheduleRepo {
  LockScheduleRepoImpl({
    required LockScheduleLocalDataSource localDataSource,
    required InstalledAppsPlatformDataSource installedAppsDataSource,
  }) : _local = localDataSource,
       _installedApps = installedAppsDataSource;

  final LockScheduleLocalDataSource _local;
  final InstalledAppsPlatformDataSource _installedApps;

  @override
  AppPickerMode get appPickerMode => _installedApps.pickerMode;

  @override
  Future<List<BlockableAppModel>> loadInstalledApps() => _installedApps.loadInstalledApps();

  @override
  UserPlanModel loadPlan() => _local.readPlan();

  @override
  Stream<UserPlanModel> get planChanges => _local.planChanges;

  @override
  Future<Either<Failure, UserPlanModel>> savePlan(LockScheduleDraftModel draft) async {
    if (!draft.isValid) return left(const ValidationFailure('plan_error_invalid'));
    try {
      // Allowed any time, even while locked (user decision): the new plan
      // applies at once — removing the meal that locked the apps unlocks
      // them. Saving also ends a "Test the lock now" lock.
      // AppBlockingRepo pushes the change to the native blocker.
      final updated = _local
          .readPlan()
          .copyWith(schedule: draft.schedule, manualLockTriggeredAt: null)
          .withAppSelection(draft.appSelection);
      await _local.savePlan(updated);
      return right(updated);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> triggerTestLockNow() async {
    try {
      final plan = _local.readPlan();
      // Behaves like a meal ending right now (the native blocker locks for real).
      await _local.savePlan(plan.copyWith(manualLockTriggeredAt: DateTime.now()));
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

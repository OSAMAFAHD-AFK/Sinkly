import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../data_sources/lock_schedule_local_data_source.dart';
import '../models/lock_schedule_draft_model.dart';
import 'lock_schedule_repo.dart';

class LockScheduleRepoImpl implements LockScheduleRepo {
  LockScheduleRepoImpl({
    required LockScheduleLocalDataSource localDataSource,
    required AppBlockingPlatformDataSource blockingDataSource,
  }) : _local = localDataSource,
       _blocking = blockingDataSource;

  final LockScheduleLocalDataSource _local;
  final AppBlockingPlatformDataSource _blocking;

  @override
  UserPlanModel loadPlan() => _local.readPlan();

  @override
  Stream<UserPlanModel> get planChanges => _local.planChanges;

  @override
  Future<Either<Failure, UserPlanModel>> savePlan(LockScheduleDraftModel draft) async {
    if (!draft.isValid) return left(const ValidationFailure('plan_error_invalid'));
    try {
      final updated = _local.readPlan().copyWith(schedule: draft.schedule, blockedAppIds: draft.blockedAppIds);
      await _local.savePlan(updated);
      await _blocking.scheduleLocks(schedule: updated.schedule, apps: updated.blockedApps);
      return right(updated);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> triggerTestLockNow() async {
    try {
      final plan = _local.readPlan();
      await _local.savePlan(plan.copyWith(manualLockTriggeredAt: DateTime.now()));
      await _blocking.lockApps(plan.blockedApps);
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

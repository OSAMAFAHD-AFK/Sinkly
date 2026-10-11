import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../models/lock_schedule_draft_model.dart';

abstract class LockScheduleRepo {
  UserPlanModel loadPlan();
  Stream<UserPlanModel> get planChanges;

  /// Persists the plan and re-schedules the native locks.
  Future<Either<Failure, UserPlanModel>> savePlan(LockScheduleDraftModel draft);

  /// Locks the apps right now — lets users try the full loop instantly.
  Future<Either<Failure, Unit>> triggerTestLockNow();
}

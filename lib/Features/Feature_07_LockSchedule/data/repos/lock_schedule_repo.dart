import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../models/lock_schedule_draft_model.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';

abstract class LockScheduleRepo {
  UserPlanModel loadPlan();
  Stream<UserPlanModel> get planChanges;

  /// Persists the plan and re-schedules the native locks.
  Future<Either<Failure, UserPlanModel>> savePlan(LockScheduleDraftModel draft);

  /// Android: our own category list · iOS: Apple's embedded picker.
  AppPickerMode get appPickerMode;

  /// Apps installed on the device (empty on iOS — Apple's picker lists them).
  Future<List<BlockableAppModel>> loadInstalledApps();
}

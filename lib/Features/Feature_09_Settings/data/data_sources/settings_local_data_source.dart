import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

abstract class SettingsLocalDataSource {
  UserPlanModel readPlan();
  Stream<UserPlanModel> get planChanges;
  Future<void> savePlan(UserPlanModel plan);
  Future<void> clearAllData();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  UserPlanModel readPlan() => _storage.plan;

  @override
  Stream<UserPlanModel> get planChanges => _storage.planChanges;

  @override
  Future<void> savePlan(UserPlanModel plan) => _storage.savePlan(plan);

  @override
  Future<void> clearAllData() => _storage.clearAll();
}

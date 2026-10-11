import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

/// Read-only access to the plan & sessions the dashboard needs.
abstract class HomeLocalDataSource {
  UserPlanModel readPlan();
  List<SinkCleaningSessionModel> readSessions();
  Stream<UserPlanModel> get planChanges;
  Stream<List<SinkCleaningSessionModel>> get sessionsChanges;
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  UserPlanModel readPlan() => _storage.plan;

  @override
  List<SinkCleaningSessionModel> readSessions() => _storage.sessions;

  @override
  Stream<UserPlanModel> get planChanges => _storage.planChanges;

  @override
  Stream<List<SinkCleaningSessionModel>> get sessionsChanges => _storage.sessionsChanges;
}

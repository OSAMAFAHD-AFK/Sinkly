import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

/// Reads the plan/history and records completed cleaning sessions.
abstract class SinkSessionLocalDataSource {
  UserPlanModel readPlan();
  List<SinkCleaningSessionModel> readSessions();
  Future<void> saveSession(SinkCleaningSessionModel session);
}

class SinkSessionLocalDataSourceImpl implements SinkSessionLocalDataSource {
  SinkSessionLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  UserPlanModel readPlan() => _storage.plan;

  @override
  List<SinkCleaningSessionModel> readSessions() => _storage.sessions;

  @override
  Future<void> saveSession(SinkCleaningSessionModel session) => _storage.addSession(session);
}

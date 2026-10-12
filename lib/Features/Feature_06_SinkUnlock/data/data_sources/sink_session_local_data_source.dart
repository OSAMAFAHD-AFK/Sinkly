import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

/// Reads the plan/history and records completed cleaning sessions.
abstract class SinkSessionLocalDataSource {
  UserPlanModel readPlan();
  List<SinkCleaningSessionModel> readSessions();
  Future<void> saveSession(SinkCleaningSessionModel session);
  Future<void> saveSprintMinutes(int minutes);
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

  @override
  Future<void> saveSprintMinutes(int minutes) => _storage.savePlan(_storage.plan.copyWith(sprintMinutes: minutes));
}

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

/// Reads what the lock overlay needs: the plan (name, apps, sprint length)
/// and the cleaning history (lock state, streak).
abstract class LockOverlayLocalDataSource {
  UserPlanModel readPlan();
  List<SinkCleaningSessionModel> readSessions();
}

class LockOverlayLocalDataSourceImpl implements LockOverlayLocalDataSource {
  LockOverlayLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  UserPlanModel readPlan() => _storage.plan;

  @override
  List<SinkCleaningSessionModel> readSessions() => _storage.sessions;
}

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

abstract class ProgressLocalDataSource {
  List<SinkCleaningSessionModel> readSessions();
  Stream<List<SinkCleaningSessionModel>> get sessionsChanges;
}

class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  ProgressLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  List<SinkCleaningSessionModel> readSessions() => _storage.sessions;

  @override
  Stream<List<SinkCleaningSessionModel>> get sessionsChanges => _storage.sessionsChanges;
}

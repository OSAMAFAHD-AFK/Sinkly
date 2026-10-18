import '../../../Feature_06_SinkUnlock/data/models/blocking_status_model.dart';
import '../models/home_dashboard_model.dart';

abstract class HomeRepo {
  HomeDashboardModel buildDashboard({required DateTime now});

  /// Emits whenever the plan or the cleaning history changes.
  Stream<void> get dataChanges;

  /// Native blocker health ("protection is off" banner).
  BlockingStatusModel get protection;
  Stream<BlockingStatusModel> get protectionChanges;

  /// Re-opens the missing access (or battery settings).
  Future<void> fixProtection();
}

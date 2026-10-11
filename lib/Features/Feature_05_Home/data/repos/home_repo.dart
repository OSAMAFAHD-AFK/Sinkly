import '../models/home_dashboard_model.dart';

abstract class HomeRepo {
  HomeDashboardModel buildDashboard({required DateTime now});

  /// Emits whenever the plan or the cleaning history changes.
  Stream<void> get dataChanges;
}

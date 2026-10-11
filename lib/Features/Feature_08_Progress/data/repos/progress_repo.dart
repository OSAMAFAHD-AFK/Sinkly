import '../models/progress_overview_model.dart';

abstract class ProgressRepo {
  ProgressOverviewModel buildOverview({required DateTime now});
  Stream<void> get dataChanges;
}

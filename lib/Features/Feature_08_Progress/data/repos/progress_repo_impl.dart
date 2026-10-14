import '../../../../core/models/shared_core_models.dart';
import '../data_sources/progress_local_data_source.dart';
import '../models/achievement_badge_model.dart';
import '../models/progress_overview_model.dart';
import 'progress_repo.dart';

class ProgressRepoImpl implements ProgressRepo {
  ProgressRepoImpl(this._local);

  final ProgressLocalDataSource _local;
  /// History card shows only the latest few so it never grows out of hand.
  static const int _recentLimit = 5;

  @override
  Stream<void> get dataChanges => _local.sessionsChanges.map((_) {});

  @override
  ProgressOverviewModel buildOverview({required DateTime now}) {
    final sessions = _local.readSessions();
    final stats = SinkProgressStatsModel.fromSessions(sessions, now: now);
    final recent = [...sessions]..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return ProgressOverviewModel(
      stats: stats,
      achievements: AchievementBadgeModel.fromStats(stats),
      recentSessions: List.unmodifiable(recent.take(_recentLimit)),
    );
  }
}

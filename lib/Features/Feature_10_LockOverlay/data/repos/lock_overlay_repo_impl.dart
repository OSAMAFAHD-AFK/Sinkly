import '../../../../core/models/shared_core_models.dart';
import '../data_sources/lock_overlay_local_data_source.dart';
import '../models/lock_overlay_snapshot_model.dart';
import 'lock_overlay_repo.dart';

class LockOverlayRepoImpl implements LockOverlayRepo {
  LockOverlayRepoImpl(this._local);

  final LockOverlayLocalDataSource _local;

  @override
  LockOverlaySnapshotModel loadSnapshot({required DateTime now, String? attemptedAppId}) {
    final plan = _local.readPlan();
    final sessions = _local.readSessions();
    final blocked = plan.blockedApps;
    final attempted = attemptedAppId == null
        ? (blocked.isEmpty ? null : blocked.first)
        : BlockableAppModel.byId(attemptedAppId) ?? BlockableAppModel.catalogForPackage(attemptedAppId);
    return LockOverlaySnapshotModel(
      lockStatus: LockStatusModel.evaluate(plan: plan, sessions: sessions, now: now),
      userName: plan.userName.trim(),
      sprintMinutes: plan.sprintMinutes,
      currentStreakDays: SinkProgressStatsModel.fromSessions(sessions, now: now).currentStreakDays,
      attemptedApp: attempted,
    );
  }
}

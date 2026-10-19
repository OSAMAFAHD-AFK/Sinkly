import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import '../data_sources/lock_overlay_local_data_source.dart';
import '../models/lock_overlay_snapshot_model.dart';
import 'lock_overlay_repo.dart';

class LockOverlayRepoImpl implements LockOverlayRepo {
  LockOverlayRepoImpl(this._local, this._blocking);

  final LockOverlayLocalDataSource _local;
  final AppBlockingRepo _blocking;

  @override
  LockOverlaySnapshotModel loadSnapshot({required DateTime now, String? attemptedAppId, String? attemptedAppName}) {
    final plan = _local.readPlan();
    final sessions = _local.readSessions();
    final blocked = plan.blockedApps;
    final id = attemptedAppId?.trim() ?? '';
    final attempted = id.isEmpty
        ? (blocked.isEmpty ? null : blocked.first)
        : BlockableAppModel.byId(id) ?? BlockableAppModel.catalogForPackage(id) ?? _fromNative(id, attemptedAppName);
    return LockOverlaySnapshotModel(
      lockStatus: LockStatusModel.evaluate(plan: plan, sessions: sessions, now: now),
      userName: plan.userName.trim(),
      sprintMinutes: plan.sprintMinutes,
      currentStreakDays: SinkProgressStatsModel.fromSessions(sessions, now: now).currentStreakDays,
      attemptedApp: attempted,
    );
  }

  /// An app the picker never listed in this session (cold start from the
  /// native lock screen): show it with the name the system gave us.
  static BlockableAppModel? _fromNative(String package, String? name) {
    final label = name?.trim() ?? '';
    if (label.isEmpty) return null;
    return BlockableAppModel(id: package, displayName: label, brandColorValue: 0xFF5AAFE6, platformIdentifier: package);
  }

  @override
  Future<void> leaveToHomeScreen() => _blocking.leaveToHomeScreen();
}

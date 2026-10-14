import '../models/lock_overlay_snapshot_model.dart';

abstract class LockOverlayRepo {
  /// [attemptedAppId] comes from the native blocker (package / app id);
  /// without it the first locked app is shown.
  LockOverlaySnapshotModel loadSnapshot({required DateTime now, String? attemptedAppId});
}

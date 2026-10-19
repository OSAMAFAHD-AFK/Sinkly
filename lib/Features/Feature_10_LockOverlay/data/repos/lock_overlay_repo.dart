import '../models/lock_overlay_snapshot_model.dart';

abstract class LockOverlayRepo {
  /// [attemptedAppId] comes from the native blocker (package / app id) with
  /// its visible [attemptedAppName]; without it the first locked app is shown.
  LockOverlaySnapshotModel loadSnapshot({required DateTime now, String? attemptedAppId, String? attemptedAppName});

  /// Android: back press on the lock screen goes to the home screen (never
  /// back into the locked app).
  Future<void> leaveToHomeScreen();
}

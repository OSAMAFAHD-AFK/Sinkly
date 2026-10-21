import '../data_sources/app_blocking_platform_data_source.dart';
import '../models/blocking_status_model.dart';

/// Keeps the native app blocker in step with the app, automatically.
///
/// Every change that matters — plan saved (onboarding or Plan tab, even
/// while locked), sink cleaned, language, subscription
/// — is pushed to the native side as one snapshot. Features never call the
/// blocker directly.
abstract class AppBlockingRepo {
  /// Starts listening and sends the first snapshot. Call once at launch.
  Future<void> start();

  /// Latest status reported by the native blocker.
  BlockingStatusModel get status;
  Stream<BlockingStatusModel> get statusChanges;

  /// Subscription state from RevenueCat / the mock: locking only runs while it
  /// is active. When it lapses everything unlocks; the plan is kept and
  /// resumes (from that moment) when the user subscribes again.
  Future<void> setSubscriptionActive(bool active);

  /// Re-sends the snapshot and refreshes the status (app resumed, etc.).
  Future<void> refresh();

  /// Opens whatever is missing (Screen Time / Usage access / overlay, or
  /// battery settings) and refreshes the status afterwards.
  Future<void> fixProtection();

  Stream<LockOverlayRequest> get lockOverlayRequests;
  Future<LockOverlayRequest?> consumeLaunchAction();
  Future<void> leaveToHomeScreen();
}

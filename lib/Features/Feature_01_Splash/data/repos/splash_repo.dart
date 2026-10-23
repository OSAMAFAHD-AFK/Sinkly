import '../../../Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../models/app_start_destination_model.dart';

abstract class SplashRepo {
  AppStartDestination resolveStartDestination();

  /// Onboarding done: may the user go to Home, or must they subscribe again
  /// (see SubscriptionRepo.hasAccess)?
  Future<bool> hasSubscriptionAccess();

  /// Sinkly was launched by tapping a locked app's lock screen (or the iOS
  /// shield notification): that request, else `null`.
  Future<LockOverlayRequest?> consumePendingLockOverlay();
}

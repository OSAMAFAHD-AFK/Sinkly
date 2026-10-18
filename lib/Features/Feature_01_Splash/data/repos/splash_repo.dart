import '../../../Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../models/app_start_destination_model.dart';

abstract class SplashRepo {
  AppStartDestination resolveStartDestination();

  /// Sinkly was launched by tapping a locked app's lock screen (or the iOS
  /// shield notification): that request, else `null`.
  Future<LockOverlayRequest?> consumePendingLockOverlay();
}

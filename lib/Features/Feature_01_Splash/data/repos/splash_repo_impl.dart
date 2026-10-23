import '../../../Feature_04_Subscription/data/repos/subscription_repo.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../../../Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import '../data_sources/splash_local_data_source.dart';
import '../models/app_start_destination_model.dart';
import 'splash_repo.dart';

class SplashRepoImpl implements SplashRepo {
  SplashRepoImpl(this._local, this._blocking, this._subscription);

  final SplashLocalDataSource _local;
  final AppBlockingRepo _blocking;
  final SubscriptionRepo _subscription;

  // Design phase is over: a finished onboarding now opens Home. (Restarting
  // onboarding on every launch would also switch app locking off, because
  // the onboarding draft marks the plan as not completed.)
  static const bool _forceOnboardingWhileDesigning = false;

  @override
  AppStartDestination resolveStartDestination() => !_forceOnboardingWhileDesigning && _local.isOnboardingCompleted()
      ? AppStartDestination.home
      : AppStartDestination.onboarding;

  @override
  Future<bool> hasSubscriptionAccess() => _subscription.hasAccess();

  @override
  Future<LockOverlayRequest?> consumePendingLockOverlay() => _blocking.consumeLaunchAction();
}

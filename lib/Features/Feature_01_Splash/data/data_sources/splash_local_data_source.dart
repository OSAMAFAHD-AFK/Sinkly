import '../../../../core/utils/local_storage_service.dart';

abstract class SplashLocalDataSource {
  /// `true` once the user finished onboarding (i.e. subscribed on the paywall).
  bool isOnboardingCompleted();
}

class SplashLocalDataSourceImpl implements SplashLocalDataSource {
  SplashLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  bool isOnboardingCompleted() => _storage.plan.onboardingCompleted;
}

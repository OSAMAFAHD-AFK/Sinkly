import '../data_sources/splash_local_data_source.dart';
import '../models/app_start_destination_model.dart';
import 'splash_repo.dart';

class SplashRepoImpl implements SplashRepo {
  SplashRepoImpl(this._local);

  final SplashLocalDataSource _local;

  // TODO(design): set to false when design is done (one-time onboarding:
  // subscribed users go straight to Home). While designing, every launch
  // starts at onboarding step 0.
  static const bool _forceOnboardingWhileDesigning = true;

  @override
  AppStartDestination resolveStartDestination() => !_forceOnboardingWhileDesigning && _local.isOnboardingCompleted()
      ? AppStartDestination.home
      : AppStartDestination.onboarding;
}

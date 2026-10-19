import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../models/onboarding_user_preferences_model.dart';
import '../models/screen_time_access_model.dart';

/// Contract used by [OnboardingCubit]. The implementation can be swapped
/// without touching the presentation layer.
abstract class OnboardingRepo {
  /// Restores the draft answers and step after an app restart.
  ({OnboardingUserPreferencesModel preferences, int stepIndex}) restoreDraft({required String languageCode});

  Future<Either<Failure, Unit>> saveDraft(OnboardingUserPreferencesModel preferences, int stepIndex);

  /// Screen Time status without prompting (iOS popup / Android Settings toggles).
  Future<Either<Failure, ScreenTimeAccessModel>> getScreenTimeAccess();

  /// Asks for the next missing Screen Time grant and returns the new status.
  Future<Either<Failure, ScreenTimeAccessModel>> requestScreenTimePermission();

  Future<Either<Failure, bool>> requestNotificationPermission();

  Future<Either<Failure, Unit>> completeOnboarding(OnboardingUserPreferencesModel preferences);

  /// Android: our own category list · iOS: Apple's embedded picker.
  AppPickerMode get appPickerMode;

  /// Apps installed on the device (empty on iOS — Apple's picker lists them).
  Future<List<BlockableAppModel>> loadInstalledApps();
}

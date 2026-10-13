import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../models/onboarding_user_preferences_model.dart';

/// Contract used by [OnboardingCubit]. Swap the implementation (e.g. one that
/// also syncs to Firestore, or one driven by Adapty Onboarding Builder)
/// without touching the presentation layer.
abstract class OnboardingRepo {
  /// Restores the draft answers and step after an app restart.
  ({OnboardingUserPreferencesModel preferences, int stepIndex}) restoreDraft({required String languageCode});

  Future<Either<Failure, Unit>> saveDraft(OnboardingUserPreferencesModel preferences, int stepIndex);

  Future<Either<Failure, bool>> requestScreenTimePermission();

  Future<Either<Failure, bool>> requestNotificationPermission();

  Future<Either<Failure, Unit>> completeOnboarding(OnboardingUserPreferencesModel preferences);

  /// Android: our own category list · iOS: Apple's embedded picker.
  AppPickerMode get appPickerMode;

  /// Apps installed on the device (empty on iOS — Apple's picker lists them).
  Future<List<BlockableAppModel>> loadInstalledApps();
}

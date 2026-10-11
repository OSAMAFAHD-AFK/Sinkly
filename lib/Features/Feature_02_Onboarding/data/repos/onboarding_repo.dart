import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
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
}

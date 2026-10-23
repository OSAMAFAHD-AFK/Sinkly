import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../../Feature_09_Settings/data/data_sources/store_review_platform_data_source.dart';
import '../data_sources/device_permissions_data_source.dart';
import '../data_sources/onboarding_local_data_source.dart';
import '../models/onboarding_user_preferences_model.dart';
import '../models/screen_time_access_model.dart';
import 'onboarding_repo.dart';

class OnboardingRepoImpl implements OnboardingRepo {
  OnboardingRepoImpl({
    required OnboardingLocalDataSource localDataSource,
    required DevicePermissionsDataSource permissionsDataSource,
    required InstalledAppsPlatformDataSource installedAppsDataSource,
    required StoreReviewPlatformDataSource storeReviewDataSource,
  }) : _local = localDataSource,
       _permissions = permissionsDataSource,
       _installedApps = installedAppsDataSource,
       _storeReview = storeReviewDataSource;

  final OnboardingLocalDataSource _local;
  final DevicePermissionsDataSource _permissions;
  final InstalledAppsPlatformDataSource _installedApps;
  final StoreReviewPlatformDataSource _storeReview;

  @override
  AppPickerMode get appPickerMode => _installedApps.pickerMode;

  @override
  Future<List<BlockableAppModel>> loadInstalledApps() => _installedApps.loadInstalledApps();

  @override
  Future<void> requestStoreReviewOnce() async {
    if (_local.readStoreReviewRequested()) return;
    // Marked first: an app restart on this step never asks twice.
    await _local.markStoreReviewRequested();
    try {
      await _storeReview.requestNativeReview();
    } catch (_) {
      // A rating sheet is a nice-to-have: never in the user's way.
    }
  }

  @override
  ({OnboardingUserPreferencesModel preferences, int stepIndex}) restoreDraft({required String languageCode}) {
    final plan = _local.readSavedPlan();
    final stepIndex = _local.readSavedStepIndex();
    if (plan.userName.isEmpty && stepIndex == 0) {
      return (preferences: OnboardingUserPreferencesModel.initial(languageCode: languageCode), stepIndex: 0);
    }
    return (
      preferences: OnboardingUserPreferencesModel.fromUserPlan(plan, languageCode: languageCode),
      stepIndex: stepIndex,
    );
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(OnboardingUserPreferencesModel preferences, int stepIndex) async {
    try {
      await _local.saveDraft(plan: preferences.toUserPlan(onboardingCompleted: false), stepIndex: stepIndex);
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, ScreenTimeAccessModel>> getScreenTimeAccess() async {
    try {
      return right(await _permissions.getScreenTimeAccess());
    } catch (error) {
      return left(PermissionFailure('error_permission_screen_time', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, ScreenTimeAccessModel>> requestScreenTimePermission() async {
    try {
      return right(await _permissions.requestScreenTimeAccess());
    } catch (error) {
      return left(PermissionFailure('error_permission_screen_time', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestNotificationPermission() async {
    try {
      return right(await _permissions.requestNotificationPermission());
    } catch (error) {
      return left(PermissionFailure('error_permission_notifications', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding(OnboardingUserPreferencesModel preferences) async {
    try {
      await _local.completeOnboarding(preferences.toUserPlan(onboardingCompleted: true));
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

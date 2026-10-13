import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Features/Feature_01_Splash/data/data_sources/splash_local_data_source.dart';
import '../../Features/Feature_01_Splash/data/repos/splash_repo.dart';
import '../../Features/Feature_01_Splash/data/repos/splash_repo_impl.dart';
import '../../Features/Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import '../../Features/Feature_02_Onboarding/data/data_sources/onboarding_local_data_source.dart';
import '../../Features/Feature_02_Onboarding/data/repos/onboarding_repo.dart';
import '../../Features/Feature_02_Onboarding/data/repos/onboarding_repo_impl.dart';
import '../../Features/Feature_03_Feedback/data/data_sources/feedback_local_data_source.dart';
import '../../Features/Feature_03_Feedback/data/repos/feedback_repo.dart';
import '../../Features/Feature_03_Feedback/data/repos/feedback_repo_impl.dart';
import '../../Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import '../../Features/Feature_04_Subscription/data/repos/subscription_repo.dart';
import '../../Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import '../../Features/Feature_05_Home/data/data_sources/home_local_data_source.dart';
import '../../Features/Feature_05_Home/data/repos/home_repo.dart';
import '../../Features/Feature_05_Home/data/repos/home_repo_impl.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_capture_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_verification_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_session_local_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/sink_unlock_repo.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/sink_unlock_repo_impl.dart';
import '../../Features/Feature_07_LockSchedule/data/data_sources/lock_schedule_local_data_source.dart';
import '../../Features/Feature_07_LockSchedule/data/repos/lock_schedule_repo.dart';
import '../../Features/Feature_07_LockSchedule/data/repos/lock_schedule_repo_impl.dart';
import '../../Features/Feature_08_Progress/data/data_sources/progress_local_data_source.dart';
import '../../Features/Feature_08_Progress/data/repos/progress_repo.dart';
import '../../Features/Feature_08_Progress/data/repos/progress_repo_impl.dart';
import '../../Features/Feature_09_Settings/data/data_sources/settings_local_data_source.dart';
import '../../Features/Feature_09_Settings/data/repos/settings_repo.dart';
import '../../Features/Feature_09_Settings/data/repos/settings_repo_impl.dart';
import 'api_service.dart';
import 'app_localizations.dart';
import 'local_storage_service.dart';

final GetIt getIt = GetIt.instance;

/// Registers every service, data source and repo.
/// Swapping a mock for a real implementation (Adapty, native
/// blocking, AI verification) is a one-line change here.
Future<void> setupServiceLocator() async {
  // ── Core ───────────────────────────────────────────────────────────────
  final preferences = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<LocalStorageService>(LocalStorageService(preferences))
    ..registerLazySingleton<LocaleController>(() => LocaleController(getIt()))
    ..registerLazySingleton<ApiService>(() => ApiService(Dio()))
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    // ── Shared platform data sources (MOCKS) ─────────────────────────────
    ..registerLazySingleton<DevicePermissionsDataSource>(PlatformDevicePermissionsDataSource.new)
    ..registerLazySingleton<AppBlockingPlatformDataSource>(MockAppBlockingPlatformDataSource.new)
    // REAL: Android device app list (MainActivity.kt) · iOS uses Apple's picker.
    ..registerLazySingleton<InstalledAppsPlatformDataSource>(MethodChannelInstalledAppsDataSource.new)
    // ── Feature 01 · Splash ──────────────────────────────────────────────
    ..registerLazySingleton<SplashLocalDataSource>(() => SplashLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<SplashRepo>(() => SplashRepoImpl(getIt()))
    // ── Feature 02 · Onboarding ──────────────────────────────────────────
    ..registerLazySingleton<OnboardingLocalDataSource>(() => OnboardingLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<OnboardingRepo>(
      () => OnboardingRepoImpl(
        localDataSource: getIt(),
        permissionsDataSource: getIt(),
        installedAppsDataSource: getIt(),
      ),
    )
    // ── Feature 03 · Feedback ────────────────────────────────────────────
    ..registerLazySingleton<FeedbackLocalDataSource>(() => FeedbackLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<FeedbackRepo>(() => FeedbackRepoImpl(localDataSource: getIt(), localeController: getIt()))
    // ── Feature 04 · Subscription (swap for AdaptySubscriptionRemoteDataSource) ─
    ..registerLazySingleton<SubscriptionRemoteDataSource>(() => MockSubscriptionRemoteDataSource(getIt()))
    ..registerLazySingleton<SubscriptionRepo>(() => SubscriptionRepoImpl(getIt()))
    // ── Feature 05 · Home ────────────────────────────────────────────────
    ..registerLazySingleton<HomeLocalDataSource>(() => HomeLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<HomeRepo>(() => HomeRepoImpl(getIt()))
    // ── Feature 06 · Sink Unlock ─────────────────────────────────────────
    ..registerLazySingleton<SinkSessionLocalDataSource>(() => SinkSessionLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<SinkPhotoCaptureDataSource>(() => SinkPhotoCaptureDataSourceImpl(getIt()))
    ..registerLazySingleton<SinkPhotoVerificationDataSource>(MockSinkPhotoVerificationDataSource.new)
    ..registerLazySingleton<SinkUnlockRepo>(
      () => SinkUnlockRepoImpl(
        sessionDataSource: getIt(),
        captureDataSource: getIt(),
        verificationDataSource: getIt(),
        blockingDataSource: getIt(),
      ),
    )
    // ── Feature 07 · Lock Schedule ───────────────────────────────────────
    ..registerLazySingleton<LockScheduleLocalDataSource>(() => LockScheduleLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<LockScheduleRepo>(
      () =>
          LockScheduleRepoImpl(localDataSource: getIt(), blockingDataSource: getIt(), installedAppsDataSource: getIt()),
    )
    // ── Feature 08 · Progress ────────────────────────────────────────────
    ..registerLazySingleton<ProgressLocalDataSource>(() => ProgressLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<ProgressRepo>(() => ProgressRepoImpl(getIt()))
    // ── Feature 09 · Settings ────────────────────────────────────────────
    ..registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<SettingsRepo>(
      () => SettingsRepoImpl(localDataSource: getIt(), permissionsDataSource: getIt(), localeController: getIt()),
    );
}

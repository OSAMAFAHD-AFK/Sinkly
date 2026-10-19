import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../Features/Feature_03_Feedback/data/data_sources/feedback_remote_data_source.dart';
import '../../Features/Feature_03_Feedback/data/repos/feedback_repo.dart';
import '../../Features/Feature_03_Feedback/data/repos/feedback_repo_impl.dart';
import '../../Features/Feature_04_Subscription/data/data_sources/revenuecat_subscription_remote_data_source.dart';
import '../../Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import '../../Features/Feature_04_Subscription/data/repos/subscription_repo.dart';
import '../../Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import '../../Features/Feature_05_Home/data/data_sources/home_local_data_source.dart';
import '../../Features/Feature_05_Home/data/repos/home_repo.dart';
import '../../Features/Feature_05_Home/data/repos/home_repo_impl.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/connectivity_probe_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_capture_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_verification_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/data_sources/sink_session_local_data_source.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/app_blocking_repo_impl.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/sink_unlock_repo.dart';
import '../../Features/Feature_06_SinkUnlock/data/repos/sink_unlock_repo_impl.dart';
import '../../Features/Feature_07_LockSchedule/data/data_sources/lock_schedule_local_data_source.dart';
import '../../Features/Feature_07_LockSchedule/data/repos/lock_schedule_repo.dart';
import '../../Features/Feature_07_LockSchedule/data/repos/lock_schedule_repo_impl.dart';
import '../../Features/Feature_08_Progress/data/data_sources/progress_local_data_source.dart';
import '../../Features/Feature_08_Progress/data/repos/progress_repo.dart';
import '../../Features/Feature_08_Progress/data/repos/progress_repo_impl.dart';
import '../../Features/Feature_09_Settings/data/data_sources/app_share_platform_data_source.dart';
import '../../Features/Feature_09_Settings/data/data_sources/settings_local_data_source.dart';
import '../../Features/Feature_09_Settings/data/data_sources/store_review_platform_data_source.dart';
import '../../Features/Feature_09_Settings/data/repos/settings_repo.dart';
import '../../Features/Feature_09_Settings/data/repos/settings_repo_impl.dart';
import '../../Features/Feature_10_LockOverlay/data/data_sources/lock_overlay_local_data_source.dart';
import '../../Features/Feature_10_LockOverlay/data/repos/lock_overlay_repo.dart';
import '../../Features/Feature_10_LockOverlay/data/repos/lock_overlay_repo_impl.dart';
import '../../Features/Feature_11_Reminders/data/data_sources/local_notifications_data_source.dart';
import '../../Features/Feature_11_Reminders/data/repos/reminders_repo.dart';
import '../../Features/Feature_11_Reminders/data/repos/reminders_repo_impl.dart';
import 'app_localizations.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

final GetIt getIt = GetIt.instance;

/// Registers every service, data source and repo.
/// Swapping a mock for a real implementation is a one-line
/// change here.
Future<void> setupServiceLocator() async {
  // ── Core ───────────────────────────────────────────────────────────────
  final preferences = await SharedPreferences.getInstance();
  // Supabase = photo check + feedback only. Unconfigured builds keep the mocks.
  final supabase = SupabaseService();
  await supabase.initialize();
  getIt
    ..registerSingleton<LocalStorageService>(LocalStorageService(preferences))
    ..registerSingleton<SupabaseService>(supabase)
    ..registerLazySingleton<LocaleController>(() => LocaleController(getIt()))
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    // ── Shared platform data sources (MOCKS) ─────────────────────────────
    // REAL on phones: notifications scheduled on the device (no server).
    ..registerLazySingleton<LocalNotificationsDataSource>(
      () => isPhone ? FlutterLocalNotificationsDataSource() : MockLocalNotificationsDataSource(),
    )
    ..registerLazySingleton<DevicePermissionsDataSource>(() => PlatformDevicePermissionsDataSource(getIt()))
    // REAL: channel `sinkly/app_blocking` (Kotlin blocking/ · Swift ios/Shared + extensions).
    ..registerLazySingleton<AppBlockingPlatformDataSource>(MethodChannelAppBlockingDataSource.new)
    ..registerLazySingleton<AppBlockingRepo>(
      () => AppBlockingRepoImpl(storage: getIt(), platform: getIt(), permissions: getIt(), localeController: getIt()),
    )
    // REAL: Android device app list (MainActivity.kt) · iOS uses Apple's picker.
    ..registerLazySingleton<InstalledAppsPlatformDataSource>(MethodChannelInstalledAppsDataSource.new)
    // ── Feature 01 · Splash ──────────────────────────────────────────────
    ..registerLazySingleton<SplashLocalDataSource>(() => SplashLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<SplashRepo>(() => SplashRepoImpl(getIt(), getIt()))
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
    ..registerLazySingleton<FeedbackRemoteDataSource>(() => SupabaseFeedbackRemoteDataSource(getIt()))
    ..registerLazySingleton<FeedbackRepo>(
      () => FeedbackRepoImpl(localDataSource: getIt(), remoteDataSource: getIt(), localeController: getIt()),
    )
    // ── Feature 04 · Subscription ────────────────────────────────────────
    // REAL once AppConstants.revenueCat*ApiKey are set: RevenueCat → stores.
    ..registerLazySingleton<SubscriptionRemoteDataSource>(
      () => RevenueCatSubscriptionRemoteDataSource.isConfigured
          ? RevenueCatSubscriptionRemoteDataSource()
          : MockSubscriptionRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<SubscriptionRepo>(
      () => SubscriptionRepoImpl(remote: getIt(), blocking: getIt(), reminders: getIt()),
    )
    // ── Feature 05 · Home ────────────────────────────────────────────────
    ..registerLazySingleton<HomeLocalDataSource>(() => HomeLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<HomeRepo>(() => HomeRepoImpl(getIt(), getIt()))
    // ── Feature 06 · Sink Unlock ─────────────────────────────────────────
    ..registerLazySingleton<SinkSessionLocalDataSource>(() => SinkSessionLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<SinkPhotoCaptureDataSource>(() => SinkPhotoCaptureDataSourceImpl(getIt()))
    // REAL once AppConstants.supabaseUrl/supabasePublishableKey are set: Edge Function → Gemini.
    ..registerLazySingleton<ConnectivityProbeDataSource>(HttpConnectivityProbeDataSource.new)
    ..registerLazySingleton<SinkPhotoVerificationDataSource>(
      () => supabase.isConfigured
          // The server confirms the subscription itself with this customer id.
          ? SupabaseSinkPhotoVerificationDataSource(getIt(), customerId: () => getIt<SubscriptionRemoteDataSource>().customerId())
          : MockSinkPhotoVerificationDataSource(),
    )
    ..registerLazySingleton<SinkUnlockRepo>(
      () => SinkUnlockRepoImpl(
        sessionDataSource: getIt(),
        captureDataSource: getIt(),
        verificationDataSource: getIt(),
        connectivityDataSource: getIt(),
      ),
    )
    // ── Feature 07 · Lock Schedule ───────────────────────────────────────
    ..registerLazySingleton<LockScheduleLocalDataSource>(() => LockScheduleLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<LockScheduleRepo>(
      () =>
          LockScheduleRepoImpl(localDataSource: getIt(), installedAppsDataSource: getIt()),
    )
    // ── Feature 08 · Progress ────────────────────────────────────────────
    ..registerLazySingleton<ProgressLocalDataSource>(() => ProgressLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<ProgressRepo>(() => ProgressRepoImpl(getIt()))
    // ── Feature 09 · Settings ────────────────────────────────────────────
    ..registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl(getIt()))
    // REAL: Apple / Google native rating sheet + system share sheet.
    ..registerLazySingleton<StoreReviewPlatformDataSource>(InAppReviewStoreReviewDataSource.new)
    ..registerLazySingleton<AppSharePlatformDataSource>(SharePlusAppShareDataSource.new)
    ..registerLazySingleton<SettingsRepo>(
      () => SettingsRepoImpl(
        localDataSource: getIt(),
        permissionsDataSource: getIt(),
        storeReviewDataSource: getIt(),
        shareDataSource: getIt(),
        localeController: getIt(),
      ),
    )
    // ── Feature 10 · Lock Overlay ────────────────────────────────────────
    ..registerLazySingleton<LockOverlayLocalDataSource>(() => LockOverlayLocalDataSourceImpl(getIt()))
    ..registerLazySingleton<LockOverlayRepo>(() => LockOverlayRepoImpl(getIt(), getIt()))
    // ── Feature 11 · Reminders (next lock · free trial ends) ─────────────
    ..registerLazySingleton<RemindersRepo>(
      () => RemindersRepoImpl(storage: getIt(), notifications: getIt(), localeController: getIt()),
    );
}

/// Real platform plugins only run on a phone; desktop / tests use mocks.
bool get isPhone => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

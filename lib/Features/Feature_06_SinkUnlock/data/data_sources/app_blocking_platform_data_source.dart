import 'package:flutter/foundation.dart';

import '../../../../core/models/shared_core_models.dart';

/// Bridge to the OS-level app blocking layer.
///
/// MOCK today. Native plan (MethodChannel `sinkly/app_blocking`):
///  * iOS: `ManagedSettingsStore().shield.applications = tokens` to lock, and
///    `= nil` to unlock. `DeviceActivityCenter().startMonitoring` schedules
///    locks at meal end-times even when Sinkly is closed (DeviceActivity
///    Monitor extension).
///  * Android: foreground service + UsageStatsManager / AccessibilityService
///    that shows the Sinkly lock overlay when a blocked package opens;
///    AlarmManager/WorkManager to trigger at meal end-times.
abstract class AppBlockingPlatformDataSource {
  Future<void> scheduleLocks({required WeeklyLockScheduleModel schedule, required List<BlockableAppModel> apps});
  Future<void> lockApps(List<BlockableAppModel> apps);
  Future<void> unlockApps(List<BlockableAppModel> apps);
}

class MockAppBlockingPlatformDataSource implements AppBlockingPlatformDataSource {
  @override
  Future<void> scheduleLocks({required WeeklyLockScheduleModel schedule, required List<BlockableAppModel> apps}) async {
    debugPrint('[AppBlocking] schedule ${schedule.weeklyMealCount} weekly locks for ${apps.map((a) => a.id).toList()}');
  }

  @override
  Future<void> lockApps(List<BlockableAppModel> apps) async =>
      debugPrint('[AppBlocking] lock ${apps.map((a) => a.id).toList()}');

  @override
  Future<void> unlockApps(List<BlockableAppModel> apps) async =>
      debugPrint('[AppBlocking] unlock ${apps.map((a) => a.id).toList()}');
}

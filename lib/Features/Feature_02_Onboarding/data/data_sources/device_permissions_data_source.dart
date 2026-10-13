import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// OS permission requests needed by Sinkly.
///
/// iOS Screen Time is REAL (`sinkly/screen_time`, AppDelegate.swift); the
/// rest is still mocked. Native wiring plan (via a MethodChannel / Pigeon plugin):
///  * iOS  — `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
///           from the FamilyControls framework (requires the Family Controls
///           entitlement), then ManagedSettings/DeviceActivity for locking.
///  * Android — Usage Access (`Settings.ACTION_USAGE_ACCESS_SETTINGS`) plus an
///           Accessibility Service or overlay to block selected packages.
///  * Notifications — `firebase_messaging` / `flutter_local_notifications`.
abstract class DevicePermissionsDataSource {
  Future<bool> requestScreenTimeAuthorization();
  Future<bool> requestNotificationPermission();
}

/// iOS: real Screen Time authorization (FamilyControls). Everything else
/// still goes through [MockDevicePermissionsDataSource] until wired.
class PlatformDevicePermissionsDataSource extends MockDevicePermissionsDataSource {
  static const MethodChannel _screenTime = MethodChannel('sinkly/screen_time');

  @override
  Future<bool> requestScreenTimeAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return super.requestScreenTimeAuthorization();
    try {
      return await _screenTime.invokeMethod<bool>('requestAuthorization') ?? false;
    } on PlatformException catch (error) {
      debugPrint('[ScreenTime] $error');
      return false;
    } on MissingPluginException {
      return super.requestScreenTimeAuthorization();
    }
  }
}

class MockDevicePermissionsDataSource implements DevicePermissionsDataSource {
  @override
  Future<bool> requestScreenTimeAuthorization() async {
    // Simulates the system sheet round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

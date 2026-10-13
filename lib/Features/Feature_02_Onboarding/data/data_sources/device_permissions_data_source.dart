import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/screen_time_access_model.dart';

/// OS permission requests needed by Sinkly.
///
/// Screen Time access is REAL on both platforms (channel `sinkly/screen_time`):
///  * iOS  — `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
///           (FamilyControls, AppDelegate.swift): Apple's own popup.
///  * Android — "Display over other apps" + "Usage access" (MainActivity.kt):
///           Android has no popup for these, so Sinkly opens the exact
///           Settings page and the call completes when the user comes back.
/// Notifications are still mocked (`firebase_messaging` /
/// `flutter_local_notifications` later).
abstract class DevicePermissionsDataSource {
  /// Current status, without asking the user anything.
  Future<ScreenTimeAccessModel> getScreenTimeAccess();

  /// Asks for the next missing grant (popup on iOS, Settings on Android) and
  /// returns the refreshed status once the user is back.
  Future<ScreenTimeAccessModel> requestScreenTimeAccess();

  /// Convenience for one-tap callers (Settings screen): true once everything
  /// Sinkly needs is granted.
  Future<bool> requestScreenTimeAuthorization() async => (await requestScreenTimeAccess()).isGranted;

  Future<bool> requestNotificationPermission();
}

class PlatformDevicePermissionsDataSource extends MockDevicePermissionsDataSource {
  static const MethodChannel _screenTime = MethodChannel('sinkly/screen_time');

  bool get _isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  Future<ScreenTimeAccessModel> getScreenTimeAccess() => _invoke('getAuthorizationStatus', super.getScreenTimeAccess);

  @override
  Future<ScreenTimeAccessModel> requestScreenTimeAccess() =>
      _invoke('requestAuthorization', super.requestScreenTimeAccess);

  Future<ScreenTimeAccessModel> _invoke(String method, Future<ScreenTimeAccessModel> Function() fallback) async {
    if (!_isMobile) return fallback();
    try {
      final status = await _screenTime.invokeMethod<Map<Object?, Object?>>(method);
      final access = ScreenTimeAccessModel.fromMap(status ?? const {});
      if (access.requirements.isEmpty) return await fallback();
      return access;
    } on MissingPluginException {
      return fallback();
    }
  }
}

/// Desktop / tests: simulates the platform flow in memory.
class MockDevicePermissionsDataSource extends DevicePermissionsDataSource {
  Set<ScreenTimeRequirement> _mockGranted = {};

  ScreenTimeAccessModel get _access => ScreenTimeAccessModel(
    requirements: defaultTargetPlatform == TargetPlatform.iOS
        ? const [ScreenTimeRequirement.familyControls]
        : const [ScreenTimeRequirement.displayOverApps, ScreenTimeRequirement.usageAccess],
    granted: _mockGranted,
  );

  @override
  Future<ScreenTimeAccessModel> getScreenTimeAccess() async => _access;

  @override
  Future<ScreenTimeAccessModel> requestScreenTimeAccess() async {
    // Simulates the system popup / Settings round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final next = _access.nextMissing;
    if (next != null) _mockGranted = {..._mockGranted, next};
    return _access;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

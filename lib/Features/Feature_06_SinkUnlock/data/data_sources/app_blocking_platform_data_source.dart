import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/blocking_snapshot_model.dart';
import '../models/blocking_status_model.dart';

/// Sent by the native lock card ("Clean my sink"): the locked app (package /
/// id + visible name; empty on iOS) and the action — always `overlay` = open
/// Sinkly's full lock screen.
typedef LockOverlayRequest = ({String appId, String appName, String action});

/// Bridge to the OS-level app blocker — channel `sinkly/app_blocking`.
///
///  * Android (`blocking/` in the Kotlin sources): a foreground service
///    watches which app comes to the front and covers a locked one with
///    Sinkly's static lock card.
///  * iOS (`ios/Shared`, extensions): ManagedSettings shields the apps with
///    the same card (Apple's shield), a DeviceActivityMonitor extension starts
///    locks at meal times even when Sinkly is closed.
///
/// Flutter → native: `apply` (snapshot) · `getStatus` · `consumeLaunchAction`
/// · `leaveToHomeScreen` · `openBatterySettings`.
/// Native → Flutter: `openLockOverlay {appId, appName, action}` ("Clean my sink").
abstract class AppBlockingPlatformDataSource {
  /// Hands the latest snapshot to the native blocker; returns its status.
  Future<BlockingStatusModel> apply(BlockingSnapshotModel snapshot);

  Future<BlockingStatusModel> status();

  /// A lock-screen request that arrived while Flutter wasn't running (cold
  /// start from the lock screen or the iOS shield notification), or `null`.
  Future<LockOverlayRequest?> consumeLaunchAction();

  /// Locked apps the user tried to open while Sinkly is running.
  Stream<LockOverlayRequest> get lockOverlayRequests;

  /// Android: leave the lock screen to the home screen (back press).
  Future<void> leaveToHomeScreen();

  /// Android: battery-optimization settings so the blocker isn't stopped.
  Future<void> openBatterySettings();
}

class MethodChannelAppBlockingDataSource implements AppBlockingPlatformDataSource {
  MethodChannelAppBlockingDataSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openLockOverlay') _requests.add(_request(call.arguments));
      return null;
    });
  }

  static const MethodChannel _channel = MethodChannel('sinkly/app_blocking');
  final StreamController<LockOverlayRequest> _requests = StreamController.broadcast();

  static LockOverlayRequest _request(Object? args) => args is Map
      ? (
          appId: args['appId'] as String? ?? '',
          appName: args['appName'] as String? ?? '',
          action: args['action'] as String? ?? 'overlay',
        )
      : (appId: '', appName: '', action: 'overlay');

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<BlockingStatusModel> apply(BlockingSnapshotModel snapshot) =>
      _status('apply', snapshot.toChannel());

  @override
  Future<BlockingStatusModel> status() => _status('getStatus');

  Future<BlockingStatusModel> _status(String method, [Object? arguments]) async {
    if (!_isMobile) return BlockingStatusModel.unknown;
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>(method, arguments);
      return map == null ? BlockingStatusModel.unknown : BlockingStatusModel.fromChannel(map);
    } on MissingPluginException {
      return BlockingStatusModel.unknown;
    }
  }

  @override
  Future<LockOverlayRequest?> consumeLaunchAction() async {
    if (!_isMobile) return null;
    try {
      final args = await _channel.invokeMethod<Map<Object?, Object?>>('consumeLaunchAction');
      return args == null ? null : _request(args);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Stream<LockOverlayRequest> get lockOverlayRequests => _requests.stream;

  @override
  Future<void> leaveToHomeScreen() => _invoke('leaveToHomeScreen');

  @override
  Future<void> openBatterySettings() => _invoke('openBatterySettings');

  Future<void> _invoke(String method) async {
    if (!_isMobile) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Older native build: nothing to do.
    }
  }
}

/// Desktop / widget tests: remembers the snapshot, never locks anything.
class MockAppBlockingPlatformDataSource implements AppBlockingPlatformDataSource {
  BlockingSnapshotModel? lastSnapshot;

  @override
  Future<BlockingStatusModel> apply(BlockingSnapshotModel snapshot) async {
    lastSnapshot = snapshot;
    return status();
  }

  @override
  Future<BlockingStatusModel> status() async =>
      BlockingStatusModel(enabled: lastSnapshot?.enabled ?? false, isLocked: false, missing: const {});

  @override
  Future<LockOverlayRequest?> consumeLaunchAction() async => null;

  @override
  Stream<LockOverlayRequest> get lockOverlayRequests => const Stream.empty();

  @override
  Future<void> leaveToHomeScreen() async {}

  @override
  Future<void> openBatterySettings() async {}
}

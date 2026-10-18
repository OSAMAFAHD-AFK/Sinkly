import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../../../Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import '../data_sources/app_blocking_platform_data_source.dart';
import '../models/blocking_snapshot_model.dart';
import '../models/blocking_status_model.dart';
import 'app_blocking_repo.dart';

class AppBlockingRepoImpl implements AppBlockingRepo {
  AppBlockingRepoImpl({
    required LocalStorageService storage,
    required AppBlockingPlatformDataSource platform,
    required DevicePermissionsDataSource permissions,
    required LocaleController localeController,
  }) : _storage = storage,
       _platform = platform,
       _permissions = permissions,
       _locale = localeController;

  // ignore_for_file: prefer_initializing_formals — public parameter names keep call sites readable.
  final LocalStorageService _storage;
  final AppBlockingPlatformDataSource _platform;
  final DevicePermissionsDataSource _permissions;
  final LocaleController _locale;

  static const String _subscriptionKey = 'sinkly.subscription_active';

  final StreamController<BlockingStatusModel> _statusController = StreamController.broadcast();
  BlockingStatusModel _status = BlockingStatusModel.unknown;
  BlockingSnapshotModel? _lastSent;
  Future<void> _queue = Future.value();
  bool _started = false;
  AppLifecycleListener? _lifecycle;

  @override
  BlockingStatusModel get status => _status;

  @override
  Stream<BlockingStatusModel> get statusChanges => _statusController.stream;

  /// TODO(dev): the onboarding "Skip to Welcome" shortcut finishes without a
  /// purchase; treat it as subscribed so locking can be tested. Goes away
  /// with [AppConstants.showDevOnboardingSkip].
  bool get _subscriptionActive => _storage.getBool(_subscriptionKey) || AppConstants.showDevOnboardingSkip;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _storage.planChanges.listen((_) => _onDataChanged());
    _storage.sessionsChanges.listen((_) => _sync());
    _locale.addListener(_sync);
    _lifecycle = AppLifecycleListener(onResume: refresh);
    await _reconcileActivation();
    await _sync(force: true);
  }

  Future<void> _onDataChanged() async {
    await _reconcileActivation();
    await _sync();
  }

  @override
  Future<void> setSubscriptionActive(bool active) async {
    if (_storage.getBool(_subscriptionKey) != active) await _storage.setBool(_subscriptionKey, active);
    await _reconcileActivation();
    await _sync();
  }

  /// Locking runs while onboarding is done AND the subscription is active.
  /// `lockingActiveSince` marks when it (re)started, so meals that ended
  /// while it was off never lock retroactively.
  Future<void> _reconcileActivation() async {
    final plan = _storage.plan;
    final enabled = plan.onboardingCompleted && _subscriptionActive;
    if (enabled && plan.lockingActiveSince == null) {
      await _storage.savePlan(plan.copyWith(lockingActiveSince: DateTime.now()));
    } else if (!enabled && plan.lockingActiveSince != null) {
      await _storage.savePlan(plan.copyWith(lockingActiveSince: null));
    }
  }

  @override
  Future<void> refresh() => _sync(force: true);

  /// Snapshots are sent one at a time, and only when something changed
  /// (unless [force]: app resumed, so alarms/time zone are re-checked).
  Future<void> _sync({bool force = false}) => _queue = _queue.then((_) async {
    try {
      final snapshot = await _buildSnapshot();
      if (!force && snapshot == _lastSent) return;
      _setStatus(await _platform.apply(snapshot));
      _lastSent = snapshot;
    } catch (error) {
      debugPrint('[AppBlocking] sync failed: $error');
    }
  });

  Future<BlockingSnapshotModel> _buildSnapshot() async {
    final plan = _storage.plan;
    final l10n = await AppLocalizations.load(_locale.locale);
    String t(String key, [Map<String, String>? params]) => l10n.translate(key, params);
    final name = plan.displayName;
    return BlockingSnapshotModel.from(
      plan: plan,
      sessions: _storage.sessions,
      enabled: plan.onboardingCompleted && _subscriptionActive && plan.lockingActiveSince != null,
      languageCode: _locale.locale.languageCode,
      strings: {
        // The static lock card over a locked app — Android draws it, iOS shows
        // it as Apple's shield. Same texts on both, in the app's language.
        'lockTitle': name.isEmpty ? t('native_lock_title') : t('native_lock_title_name', {'name': name}),
        'lockSubtitle': t('native_lock_subtitle'),
        'lockCta': t('native_lock_cta'),
        'lockHome': t('native_lock_home'),
        // Android only (iOS doesn't say which app): `{app}` is filled in natively.
        'lockChip': t('lock_overlay_chip_paused', {'app': '{app}'}),
        'appsGeneric': t('lock_overlay_apps_generic'),
        'notifyTitle': t('native_notify_title'),
        'notifyBody': t('native_notify_body'),
        'serviceChannel': t('native_service_channel'),
        'serviceLocked': t('native_service_locked'),
        'serviceActive': t('native_service_active'),
        // `{time}` is filled in natively, in the phone's own time format.
        'serviceNext': t('native_service_next'),
        'serviceIdle': t('native_service_idle'),
      },
    );
  }

  void _setStatus(BlockingStatusModel status) {
    if (status == _status) return;
    _status = status;
    _statusController.add(status);
  }

  @override
  Future<void> fixProtection() async {
    final missing = _status.missing;
    if (missing.any((requirement) => requirement != BlockingRequirement.batteryOptimization)) {
      await _permissions.requestScreenTimeAccess();
    } else if (missing.contains(BlockingRequirement.batteryOptimization)) {
      await _platform.openBatterySettings();
    }
    await refresh();
  }

  @override
  Stream<LockOverlayRequest> get lockOverlayRequests => _platform.lockOverlayRequests;

  @override
  Future<LockOverlayRequest?> consumeLaunchAction() => _platform.consumeLaunchAction();

  @override
  Future<void> leaveToHomeScreen() => _platform.leaveToHomeScreen();

  @visibleForTesting
  void dispose() {
    _lifecycle?.dispose();
    _locale.removeListener(_sync);
  }
}

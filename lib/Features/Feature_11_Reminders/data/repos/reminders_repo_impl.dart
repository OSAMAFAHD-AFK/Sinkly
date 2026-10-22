import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/crash_reporting_service.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../data_sources/local_notifications_data_source.dart';
import '../models/reminder_model.dart';
import 'reminders_repo.dart';

class RemindersRepoImpl implements RemindersRepo {
  RemindersRepoImpl({
    required LocalStorageService storage,
    required LocalNotificationsDataSource notifications,
    required LocaleController localeController,
    DateTime Function()? clock,
  }) : _storage = storage,
       _notifications = notifications,
       _locale = localeController,
       _now = clock ?? DateTime.now;

  // ignore_for_file: prefer_initializing_formals — named parameters keep call sites readable.
  final LocalStorageService _storage;
  final LocalNotificationsDataSource _notifications;
  final LocaleController _locale;
  final DateTime Function() _now;

  /// Reminder before each lock = the end of a planned meal.
  static const Duration lockLead = Duration(minutes: 15);

  /// Trial reminder: one day before the first charge.
  static const Duration trialLead = Duration(days: 1);

  /// How far ahead lock reminders are planned (re-planned on every app open).
  static const Duration lockHorizon = Duration(days: 7);

  static const String _trialChargeAtKey = 'sinkly.trial_charge_at';
  static const String _trialRemindedForKey = 'sinkly.trial_reminder_for';

  Future<void> _queue = Future.value();
  bool _started = false;
  List<ReminderModel>? _plannedLocks;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _notifications.initialize();
    _storage.planChanges.listen((_) => refresh());
    _locale.addListener(_onLocaleChanged);
    AppLifecycleListener(onResume: refresh);
    await refresh();
  }

  void _onLocaleChanged() {
    _plannedLocks = null; // texts changed: plan again even if the times didn't
    refresh();
  }

  @override
  Future<void> setTrialChargeAt(DateTime? chargeAt) async {
    final stored = chargeAt?.toUtc().toIso8601String();
    if (stored == _storage.getString(_trialChargeAtKey)) return refresh();
    await _storage.setString(_trialChargeAtKey, stored ?? '');
    await refresh();
  }

  /// One plan at a time, so quick successive changes can't interleave.
  @override
  Future<void> refresh() => _queue = _queue.then((_) async {
    try {
      final texts = await _Texts.load(_locale.locale);
      await _syncLocks(texts);
      await _syncTrial(texts);
    } catch (error, stack) {
      CrashReportingService.recordError(error, stack, reason: 'reminders');
    }
  });

  bool get _enabled {
    final plan = _storage.plan;
    return plan.notificationsEnabled && plan.onboardingCompleted;
  }

  // ── Next lock ──────────────────────────────────────────────────────────
  Future<void> _syncLocks(_Texts texts) async {
    final plan = _storage.plan;
    final now = _now();
    final wanted = <ReminderModel>[];
    // Only while locking runs (onboarding done + subscribed).
    if (_enabled && plan.lockingActiveSince != null) {
      final triggers = plan.schedule.lockTriggersBetween(now.add(lockLead), now.add(lockHorizon));
      for (final trigger in triggers.take(ReminderModel.maxLockReminders)) {
        wanted.add(
          ReminderModel(
            id: ReminderModel.firstLockId + wanted.length,
            at: trigger.at.subtract(lockLead),
            title: texts.tr('reminder_lock_title', {'time': texts.clock(trigger.at)}),
            body: texts.tr('reminder_lock_body', {'meal': texts.tr(trigger.meal.translationKey)}),
            channelId: 'sinkly_lock_reminders',
            channelName: texts.tr('reminder_channel_locks'),
          ),
        );
      }
    }
    if (_sameAs(_plannedLocks, wanted)) return;

    final pending = await _notifications.pendingIds();
    for (var id = ReminderModel.firstLockId; id < ReminderModel.firstLockId + ReminderModel.maxLockReminders; id++) {
      if (pending.contains(id) && id >= ReminderModel.firstLockId + wanted.length) await _notifications.cancel(id);
    }
    for (final reminder in wanted) {
      await _notifications.schedule(reminder);
    }
    _plannedLocks = wanted;
  }

  static bool _sameAs(List<ReminderModel>? a, List<ReminderModel> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── Free trial ends ────────────────────────────────────────────────────
  /// A billing notice, not a nudge: the paywall promises it, so it ignores
  /// the Reminders switch (only the phone's notification permission can stop
  /// it).
  Future<void> _syncTrial(_Texts texts) async {
    final chargeAt = DateTime.tryParse(_storage.getString(_trialChargeAtKey) ?? '');
    final now = _now();
    if (!_storage.plan.onboardingCompleted || chargeAt == null || !chargeAt.isAfter(now)) {
      await _notifications.cancel(ReminderModel.trialEndId);
      return;
    }

    final chargeKey = chargeAt.toUtc().toIso8601String();
    final remindAt = chargeAt.subtract(trialLead);
    final alreadyPlanned = _storage.getString(_trialRemindedForKey) == chargeKey;

    DateTime? at;
    String titleKey = 'reminder_trial_title_tomorrow';
    if (remindAt.isAfter(now.add(const Duration(minutes: 1)))) {
      at = remindAt;
    } else if (!alreadyPlanned && chargeAt.difference(now) >= const Duration(hours: 2)) {
      // Less than a day left and never reminded (e.g. notification
      // permission was just granted): remind now rather than not at all.
      at = now.add(const Duration(minutes: 1));
      titleKey = 'reminder_trial_title_today';
    }
    if (at == null) return; // Already shown for this trial.

    await _notifications.schedule(
      ReminderModel(
        id: ReminderModel.trialEndId,
        at: at,
        title: texts.tr(titleKey),
        body: texts.tr('reminder_trial_body', {'store': Platform.isIOS ? 'App Store' : 'Google Play'}),
        channelId: 'sinkly_subscription_reminders',
        channelName: texts.tr('reminder_channel_trial'),
      ),
    );
    await _storage.setString(_trialRemindedForKey, chargeKey);
  }

  void dispose() => _locale.removeListener(_onLocaleChanged);
}

/// Translations + the phone's clock format, without a BuildContext.
class _Texts {
  _Texts(this._l10n, this._material);

  final AppLocalizations _l10n;
  final MaterialLocalizations _material;

  static Future<_Texts> load(Locale locale) async =>
      _Texts(await AppLocalizations.load(locale), await GlobalMaterialLocalizations.delegate.load(locale));

  String tr(String key, [Map<String, String>? params]) => _l10n.translate(key, params);

  /// Same rule as the app: 0-9 digits, localized AM/PM, phone's 12/24 h.
  String clock(DateTime at) => AppFunctions.westernDigits(
    _material.formatTimeOfDay(
      TimeOfDay(hour: at.hour, minute: at.minute),
      alwaysUse24HourFormat: PlatformDispatcher.instance.alwaysUse24HourFormat,
    ),
  );
}

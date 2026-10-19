import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';

/// Notifications scheduled ON the phone: no server, no Firebase. They fire
/// even when Sinkly is closed (the OS keeps them, Android re-adds them after
/// a reboot) and disappear with the app if it is uninstalled.
abstract class LocalNotificationsDataSource {
  Future<void> initialize();

  /// The system "Allow notifications?" prompt (Android 13+ / iOS). `true`
  /// when notifications may be shown.
  Future<bool> requestPermission();

  /// Replaces any pending reminder with the same id.
  Future<void> schedule(ReminderModel reminder);

  Future<void> cancel(int id);

  /// Ids of the reminders still waiting to fire.
  Future<Set<int>> pendingIds();
}

class FlutterLocalNotificationsDataSource implements LocalNotificationsDataSource {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;

  @override
  Future<void> initialize() => _initializing ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          // White silhouette for the status bar (res/drawable/ic_stat_sinkly.xml).
          android: AndroidInitializationSettings('ic_stat_sinkly'),
          // Asked at the right moment in onboarding, never at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      )
      .then((_) {});

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> schedule(ReminderModel reminder) async {
    await initialize();
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      // An exact instant: the local wall-clock maths (DST…) is already done.
      scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminder.channelId,
          reminder.channelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(reminder.body),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      // A minute or two late is fine for a reminder; needs no special permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return {for (final request in pending) request.id};
  }
}

/// Desktop / widget tests: keeps the schedule in memory.
class MockLocalNotificationsDataSource implements LocalNotificationsDataSource {
  final Map<int, ReminderModel> scheduled = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<void> schedule(ReminderModel reminder) async => scheduled[reminder.id] = reminder;

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();
}

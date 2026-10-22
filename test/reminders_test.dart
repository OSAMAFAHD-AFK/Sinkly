import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_11_Reminders/data/data_sources/local_notifications_data_source.dart';
import 'package:sinkly/Features/Feature_11_Reminders/data/models/reminder_model.dart';
import 'package:sinkly/Features/Feature_11_Reminders/data/repos/reminders_repo_impl.dart';
import 'package:sinkly/core/models/shared_core_models.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2026-10-12 is a Monday. Default plan: breakfast ends 9:30, dinner 21:00, every day.
  final now = DateTime(2026, 10, 12, 10);

  Future<({RemindersRepoImpl repo, MockLocalNotificationsDataSource notifications, LocalStorageService storage})> setUp({
    bool notifications = true,
    bool lockingActive = true,
  }) async {
    SharedPreferences.setMockInitialValues({'sinkly.locale': 'en'});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    await storage.savePlan(
      UserPlanModel.initial().copyWith(
        onboardingCompleted: true,
        notificationsEnabled: notifications,
        lockingActiveSince: lockingActive ? DateTime(2026, 10, 1) : null,
      ),
    );
    final mock = MockLocalNotificationsDataSource();
    final repo = RemindersRepoImpl(
      storage: storage,
      notifications: mock,
      localeController: LocaleController(storage),
      clock: () => now,
    );
    return (repo: repo, notifications: mock, storage: storage);
  }

  group('free trial reminder', () {
    test('fires once, one day before the first charge', () async {
      final s = await setUp();
      final chargeAt = now.add(const Duration(days: 3));
      await s.repo.setTrialChargeAt(chargeAt);

      final reminder = s.notifications.scheduled[ReminderModel.trialEndId];
      expect(reminder, isNotNull);
      expect(reminder!.at.isAtSameMomentAs(chargeAt.subtract(const Duration(days: 1))), isTrue);
      expect(reminder.title, 'Your free trial ends tomorrow');
      expect(reminder.body, contains('Google Play'));
    });

    test('is removed when the user cancels (no charge coming)', () async {
      final s = await setUp();
      await s.repo.setTrialChargeAt(now.add(const Duration(days: 3)));
      await s.repo.setTrialChargeAt(null);
      expect(s.notifications.scheduled.containsKey(ReminderModel.trialEndId), isFalse);
    });

    test('ignores the Reminders switch (billing notice the paywall promises)', () async {
      final s = await setUp(notifications: false);
      await s.repo.setTrialChargeAt(now.add(const Duration(days: 3)));
      expect(s.notifications.scheduled.keys, [ReminderModel.trialEndId]);
    });

    test('less than a day left and never reminded: reminds right away', () async {
      final s = await setUp();
      await s.repo.setTrialChargeAt(now.add(const Duration(hours: 10)));
      final reminder = s.notifications.scheduled[ReminderModel.trialEndId]!;
      expect(reminder.title, 'Your free trial ends today');
      expect(reminder.at.difference(now), const Duration(minutes: 1));
    });
  });

  group('next lock reminders', () {
    test('15 minutes before each meal end, for the coming week', () async {
      final s = await setUp();
      await s.repo.refresh();

      final locks = s.notifications.scheduled.values.where((r) => r.id >= ReminderModel.firstLockId).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      expect(locks, isNotEmpty);
      expect(locks.first.at, DateTime(2026, 10, 12, 20, 45)); // dinner ends 21:00
      expect(locks.first.title, contains('9:00'));
      expect(locks.first.body, contains('Dinner'));
      expect(locks.every((r) => r.at.isAfter(now)), isTrue);
    });

    test('nothing while locking is off (not subscribed)', () async {
      final s = await setUp(lockingActive: false);
      await s.repo.refresh();
      expect(s.notifications.scheduled, isEmpty);
    });

    test('turning reminders off removes them', () async {
      final s = await setUp();
      await s.repo.refresh();
      expect(s.notifications.scheduled, isNotEmpty);

      await s.storage.savePlan(s.storage.plan.copyWith(notificationsEnabled: false));
      await s.repo.refresh();
      expect(s.notifications.scheduled, isEmpty);
    });
  });
}

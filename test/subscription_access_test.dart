import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_01_Splash/data/models/app_start_destination_model.dart';
import 'package:sinkly/Features/Feature_01_Splash/data/repos/splash_repo.dart';
import 'package:sinkly/Features/Feature_01_Splash/presentation/manager/splash_cubit.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_step_widget.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/models/subscription_status_model.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/repos/app_blocking_repo_impl.dart';
import 'package:sinkly/Features/Feature_11_Reminders/data/data_sources/local_notifications_data_source.dart';
import 'package:sinkly/Features/Feature_11_Reminders/data/repos/reminders_repo_impl.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

/// The store's answer, scripted per test.
class _ScriptedRemote extends MockSubscriptionRemoteDataSource {
  _ScriptedRemote(super.storage);

  FutureOr<SubscriptionStatusModel> Function() answer = () => SubscriptionStatusModel.inactive;

  @override
  Future<SubscriptionStatusModel> currentStatus() async => answer();
}

class _FakeSplashRepo implements SplashRepo {
  _FakeSplashRepo(this.destination, {this.access = true});

  final AppStartDestination destination;
  final bool access;
  bool accessAsked = false;

  @override
  AppStartDestination resolveStartDestination() => destination;

  @override
  Future<bool> hasSubscriptionAccess() async {
    accessAsked = true;
    return access;
  }

  @override
  Future<LockOverlayRequest?> consumePendingLockOverlay() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({SubscriptionRepoImpl repo, _ScriptedRemote remote})> setUp([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    final locale = LocaleController(storage);
    final remote = _ScriptedRemote(storage);
    final repo = SubscriptionRepoImpl(
      remote: remote,
      blocking: AppBlockingRepoImpl(
        storage: storage,
        platform: MockAppBlockingPlatformDataSource(),
        permissions: MockDevicePermissionsDataSource(),
        localeController: locale,
      ),
      reminders: RemindersRepoImpl(
        storage: storage,
        notifications: MockLocalNotificationsDataSource(),
        localeController: locale,
      ),
      storage: storage,
    );
    return (repo: repo, remote: remote);
  }

  group('app open: paywall only for a store-confirmed lapse', () {
    test('confirmed: no active subscription → paywall', () async {
      final s = await setUp();
      expect(await s.repo.hasAccess(), isFalse);
    });

    test('free trial and billing grace period count as active', () async {
      final s = await setUp();
      s.remote.answer = () => const SubscriptionStatusModel(isActive: true, isInTrial: true, willRenew: true);
      expect(await s.repo.hasAccess(), isTrue);
      // Grace period: the store keeps the entitlement active while it retries.
      s.remote.answer = () => const SubscriptionStatusModel(isActive: true, willRenew: true);
      expect(await s.repo.hasAccess(), isTrue);
    });

    test('offline (old cached answer) never locks a subscriber out', () async {
      final s = await setUp();
      s.remote.answer = () => const SubscriptionStatusModel(isActive: false, confirmed: false);
      expect(await s.repo.hasAccess(), isTrue);
    });

    test('store unreachable → last confirmed answer', () async {
      final s = await setUp();
      s.remote.answer = () => const SubscriptionStatusModel(isActive: true);
      expect(await s.repo.hasAccess(), isTrue);
      s.remote.answer = () => throw const SocketException('offline');
      expect(await s.repo.hasAccess(), isTrue);

      s.remote.answer = () => SubscriptionStatusModel.inactive;
      expect(await s.repo.hasAccess(), isFalse);
      s.remote.answer = () => throw const SocketException('offline');
      expect(await s.repo.hasAccess(), isFalse);
    });

    test('store too slow → decided without waiting forever', () async {
      final s = await setUp();
      s.remote.answer = () => Future.delayed(const Duration(seconds: 5), () => SubscriptionStatusModel.inactive);
      expect(await s.repo.hasAccess(timeout: const Duration(milliseconds: 50)), isTrue);
    });
  });

  group('splash', () {
    test('onboarding done + lapsed → paywall', () async {
      final repo = _FakeSplashRepo(AppStartDestination.home, access: false);
      final cubit = SplashCubit(repo);
      await cubit.start(Duration.zero);
      expect(cubit.state, AppStartDestination.paywall);
    });

    test('onboarding done + subscribed → Home', () async {
      final cubit = SplashCubit(_FakeSplashRepo(AppStartDestination.home));
      await cubit.start(Duration.zero);
      expect(cubit.state, AppStartDestination.home);
    });

    test('new user: onboarding, the store is not even asked', () async {
      final repo = _FakeSplashRepo(AppStartDestination.onboarding, access: false);
      final cubit = SplashCubit(repo);
      await cubit.start(Duration.zero);
      expect(cubit.state, AppStartDestination.onboarding);
      expect(repo.accessAsked, isFalse);
    });
  });

  group('paywall headline', () {
    test('promises the free trial only when the plan has one', () {
      expect(PaywallStepWidget.titleKey(hasTrial: true, hasName: true), 'paywall_title');
      expect(PaywallStepWidget.titleKey(hasTrial: true, hasName: false), 'paywall_title_generic');
      expect(PaywallStepWidget.titleKey(hasTrial: false, hasName: true), 'paywall_title_subscribe');
      expect(PaywallStepWidget.titleKey(hasTrial: false, hasName: false), 'paywall_title_subscribe_generic');
    });

    test('no-trial headlines exist in every language and never say "free"', () {
      const free = {
        'en': 'free', 'ar': 'مجان', 'de': 'gratis', 'es': 'grat', 'fr': 'gratuit',
        'hi': 'फ़्री', 'it': 'gratuit', 'ja': '無料', 'ko': '무료', 'pt': 'grát',
      };
      for (final MapEntry(key: lang, value: word) in free.entries) {
        final strings = jsonDecode(File('assets/translations/$lang.json').readAsStringSync()) as Map<String, dynamic>;
        for (final key in ['paywall_title_subscribe', 'paywall_title_subscribe_generic']) {
          final text = strings[key] as String?;
          expect(text, isNotNull, reason: '$lang.$key');
          expect(text!.toLowerCase().contains(word), isFalse, reason: '$lang.$key');
        }
        expect((strings['paywall_title_subscribe'] as String).contains('{name}'), isTrue, reason: lang);
      }
    });
  });
}

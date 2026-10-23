import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/crash_reporting_service.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../../../Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import '../../../Feature_11_Reminders/data/repos/reminders_repo.dart';
import '../data_sources/subscription_remote_data_source.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';
import 'subscription_repo.dart';

class SubscriptionRepoImpl implements SubscriptionRepo {
  SubscriptionRepoImpl({
    required SubscriptionRemoteDataSource remote,
    required AppBlockingRepo blocking,
    required RemindersRepo reminders,
    required LocalStorageService storage,
  }) : _remote = remote,
       _blocking = blocking,
       _reminders = reminders,
       _storage = storage;

  // ignore_for_file: prefer_initializing_formals — named parameters keep call sites readable.
  final SubscriptionRemoteDataSource _remote;

  /// Locking runs only while the subscription is active (user decision).
  final AppBlockingRepo _blocking;

  /// "Your free trial ends tomorrow", one day before the first charge.
  final RemindersRepo _reminders;

  /// Keeps the store's last confirmed answer for [hasAccess] when offline.
  final LocalStorageService _storage;
  static const String _lastConfirmedKey = 'sinkly.subscription_last_confirmed';

  SubscriptionStatusModel? _status;
  final StreamController<bool> _premiumChanges = StreamController.broadcast();
  bool _started = false;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _remote.initialize();
      _remote.statusChanges.listen(_apply);
      await isPremiumActive();
    } catch (error, stack) {
      CrashReportingService.recordError(error, stack, reason: 'subscriptions start');
    }
  }

  /// Every fresh answer from the store reaches the blocker and the reminder.
  Future<bool> _apply(SubscriptionStatusModel status) async {
    _status = status;
    final active = status.isActive;
    _premiumChanges.add(active);
    if (status.confirmed) await _storage.setString(_lastConfirmedKey, active ? 'active' : 'inactive');
    await _blocking.setSubscriptionActive(active);
    await _reminders.setTrialChargeAt(status.firstChargeAt);
    return active;
  }

  @override
  Future<Either<Failure, List<SubscriptionPlanModel>>> fetchPaywallPlans({required String placementId}) async {
    try {
      return right(await _remote.fetchPaywallPlans(placementId: placementId));
    } catch (error, stack) {
      // No plans = no sales: always worth knowing about.
      CrashReportingService.recordError(error, stack, reason: 'paywall load ($placementId)');
      return left(ServerFailure('error_paywall_load', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> purchase(SubscriptionPlanModel plan) async {
    try {
      return right(await _apply(await _remote.purchase(plan)));
    } on PurchaseCancelledException {
      return left(const PurchaseFailure('error_purchase_cancelled', userCancelled: true));
    } on PurchasePendingException {
      return left(const PurchaseFailure(SubscriptionRepo.paymentPendingKey));
    } catch (error, stack) {
      CrashReportingService.recordError(error, stack, reason: 'purchase ${plan.vendorProductId}');
      return left(PurchaseFailure('error_purchase', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> restorePurchases() async {
    try {
      return right(await _apply(await _remote.restorePurchases()));
    } catch (error, stack) {
      CrashReportingService.recordError(error, stack, reason: 'restore');
      return left(PurchaseFailure('error_restore', debugMessage: '$error'));
    }
  }

  @override
  Future<bool> isPremiumActive() async {
    try {
      return await _apply(await _remote.currentStatus());
    } catch (_) {
      // Unknown (e.g. offline): keep the last answer; the blocker keeps its
      // own last known state too.
      return _status?.isActive ?? false;
    }
  }

  @override
  Future<bool> hasAccess({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final status = await _remote.currentStatus().timeout(timeout);
      await _apply(status);
      if (status.confirmed) return status.isActive;
    } catch (_) {
      // Offline / store down / too slow: decided below, never a lock-out.
    }
    return _storage.getString(_lastConfirmedKey) != 'inactive';
  }

  @override
  Stream<bool> get premiumChanges => _premiumChanges.stream;

  @override
  Future<void> logPaywallShown({required String placementId}) async {
    try {
      await _remote.logPaywallShown(placementId: placementId);
    } catch (_) {
      // Analytics must never block the paywall.
    }
  }

  @override
  Future<String> manageSubscriptionUrl() async {
    final fromStore = _status?.managementUrl;
    if (fromStore != null && fromStore.isNotEmpty) return fromStore;
    return Platform.isIOS ? AppConstants.appleSubscriptionsUrl : AppConstants.googleSubscriptionsUrl;
  }

  @override
  Future<bool> openCustomerCenter() async {
    try {
      return await _remote.presentCustomerCenter();
    } catch (error, stack) {
      // Not set up in the dashboard / not supported here: the store page instead.
      CrashReportingService.recordError(error, stack, reason: 'customer center');
      return false;
    }
  }
}

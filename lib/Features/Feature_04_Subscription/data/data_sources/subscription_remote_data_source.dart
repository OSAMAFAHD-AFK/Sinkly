import 'dart:async';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';

/// Contract between Sinkly and the subscription provider.
/// Implementations: [RevenueCatSubscriptionRemoteDataSource]
/// (revenuecat_subscription_remote_data_source.dart) once the RevenueCat keys
/// are set in [AppConstants], and [MockSubscriptionRemoteDataSource] until then.
abstract class SubscriptionRemoteDataSource {
  /// Connects to the provider. Call once at launch, before anything else.
  Future<void> initialize();

  /// Products configured for a paywall placement
  /// ([AppConstants.onboardingPaywallPlacementId], …).
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId});

  /// Buys [plan]. Throws [PurchaseCancelledException] when the user closes
  /// the store sheet.
  Future<SubscriptionStatusModel> purchase(SubscriptionPlanModel plan);

  Future<SubscriptionStatusModel> restorePurchases();

  Future<SubscriptionStatusModel> currentStatus();

  /// Every change the store reports (renewal, cancellation, refund, expiry…).
  Stream<SubscriptionStatusModel> get statusChanges;

  /// Must be called every time OUR custom paywall becomes visible so the
  /// provider attributes views → purchases (paywall analytics / experiments).
  Future<void> logPaywallShown({required String placementId});

  /// The id the provider knows this customer by. Sent with each photo check
  /// so the server can confirm the subscription itself.
  Future<String?> customerId();

  /// The provider's own subscription management screen (RevenueCat Customer
  /// Center). `false` when there is none, so the caller opens the store page.
  Future<bool> presentCustomerCenter();
}

/// The user closed the store's purchase sheet: not an error to show.
class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
}

/// Offline mock with realistic latency. Remembers the purchase locally so the
/// full app flow (trial, reminder, blocking) can be tested without the stores.
class MockSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  MockSubscriptionRemoteDataSource(this._storage);

  final LocalStorageService _storage;
  final StreamController<SubscriptionStatusModel> _changes = StreamController.broadcast();
  static const String _premiumKey = 'sinkly.mock_premium_active';
  static const String _purchasedAtKey = 'sinkly.mock_purchased_at';

  @override
  Future<void> initialize() async {}

  @override
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    // PLACEHOLDER prices (the real ones come from the stores via RevenueCat).
    // Weekly $4.99 · Annual $39.99 · Exit-offer annual $29.99. Every figure
    // below is derived from those three (52 weeks a year):
    //   annual      $39.99 → $0.77/week · 85% less than 52 × $4.99 = $259.48
    //   exit offer  $29.99 → $0.58/week · 88% less than weekly all year,
    //                         25% less than the regular annual
    if (placementId == AppConstants.exitOfferPlacementId) {
      // Exit offer: the SAME annual plan, 25% cheaper. In the stores this is
      // its own product in the same subscription group.
      return const [
        SubscriptionPlanModel(
          id: 'annual_exit_offer',
          vendorProductId: 'sinkly_premium_annual_special',
          period: SubscriptionPeriod.annual,
          localizedPrice: r'$29.99',
          localizedPricePerWeek: r'$0.58',
          trialDays: AppConstants.freeTrialDays,
          savingVsWeeklyPercent: 88,
          discountPercent: 25,
          originalLocalizedPrice: r'$39.99',
        ),
      ];
    }
    return const [
      SubscriptionPlanModel(
        id: 'annual',
        vendorProductId: 'sinkly_premium_annual',
        period: SubscriptionPeriod.annual,
        localizedPrice: r'$39.99',
        localizedPricePerWeek: r'$0.77',
        trialDays: AppConstants.freeTrialDays,
        savingVsWeeklyPercent: 85,
      ),
      SubscriptionPlanModel(
        id: 'weekly',
        vendorProductId: 'sinkly_premium_weekly',
        period: SubscriptionPeriod.weekly,
        localizedPrice: r'$4.99',
        localizedPricePerWeek: r'$4.99',
        trialDays: AppConstants.freeTrialDays,
      ),
    ];
  }

  @override
  Future<SubscriptionStatusModel> purchase(SubscriptionPlanModel plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _storage.setBool(_premiumKey, true);
    await _storage.setString(_purchasedAtKey, DateTime.now().toUtc().toIso8601String());
    final status = await currentStatus();
    _changes.add(status);
    return status;
  }

  @override
  Future<SubscriptionStatusModel> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return currentStatus();
  }

  /// A purchase starts a renewing free trial, like the real stores.
  @override
  Future<SubscriptionStatusModel> currentStatus() async {
    if (!_storage.getBool(_premiumKey)) return SubscriptionStatusModel.inactive;
    final purchasedAt = DateTime.tryParse(_storage.getString(_purchasedAtKey) ?? '');
    final trialEnd = purchasedAt?.add(const Duration(days: AppConstants.freeTrialDays));
    final inTrial = trialEnd != null && trialEnd.isAfter(DateTime.now());
    return SubscriptionStatusModel(isActive: true, isInTrial: inTrial, willRenew: true, expiresAt: trialEnd);
  }

  @override
  Stream<SubscriptionStatusModel> get statusChanges => _changes.stream;

  @override
  Future<void> logPaywallShown({required String placementId}) async {}

  @override
  Future<String?> customerId() async => null;

  @override
  Future<bool> presentCustomerCenter() async => false;
}

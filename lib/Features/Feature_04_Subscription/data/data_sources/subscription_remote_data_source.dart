import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../models/subscription_plan_model.dart';

/// Contract between Sinkly and the subscription provider.
/// Implementations: [MockSubscriptionRemoteDataSource] (today) and
/// `AdaptySubscriptionRemoteDataSource` (see adapty_subscription_remote_data_source.dart).
abstract class SubscriptionRemoteDataSource {
  /// Products configured for a paywall placement.
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId});

  /// Returns `true` when the premium access level becomes active.
  Future<bool> purchase(SubscriptionPlanModel plan);

  Future<bool> restorePurchases();

  Future<bool> isPremiumActive();

  /// Must be called every time OUR custom paywall becomes visible so the
  /// provider attributes views → purchases (Adapty: `logShowPaywall`).
  Future<void> logPaywallShown({required String placementId});
}

/// Offline mock with realistic latency. Remembers the premium flag locally so
/// the full app flow can be tested end-to-end without store sandboxes.
class MockSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  MockSubscriptionRemoteDataSource(this._storage);

  final LocalStorageService _storage;
  static const String _premiumKey = 'sinkly.mock_premium_active';

  @override
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    // PLACEHOLDER prices (the real ones come from the stores via Adapty).
    // Weekly $4.99 · Annual $39.99 · Exit-offer annual $29.99. Every figure
    // below is derived from those three (52 weeks a year):
    //   annual      $39.99 → $0.77/week · 85% less than 52 × $4.99 = $259.48
    //   exit offer  $29.99 → $0.58/week · 88% less than weekly all year,
    //                         25% less than the regular annual
    if (placementId == AppConstants.adaptyExitOfferPlacementId) {
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
  Future<bool> purchase(SubscriptionPlanModel plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _storage.setBool(_premiumKey, true);
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return _storage.getBool(_premiumKey);
  }

  @override
  Future<bool> isPremiumActive() async => _storage.getBool(_premiumKey);

  @override
  Future<void> logPaywallShown({required String placementId}) async =>
      debugPrint('[Subscription] paywall shown: $placementId');
}

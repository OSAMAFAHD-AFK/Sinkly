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
    return const [
      SubscriptionPlanModel(
        id: 'annual',
        vendorProductId: 'sinkly_premium_annual',
        period: SubscriptionPeriod.annual,
        localizedPrice: r'$29.99',
        localizedPricePerWeek: r'$0.58',
        trialDays: AppConstants.freeTrialDays,
        discountPercent: 50,
      ),
      SubscriptionPlanModel(
        id: 'monthly',
        vendorProductId: 'sinkly_premium_monthly',
        period: SubscriptionPeriod.monthly,
        localizedPrice: r'$4.99',
        localizedPricePerWeek: r'$1.15',
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
}

import '../models/subscription_plan_model.dart';
import 'subscription_remote_data_source.dart';

/// ADAPTY INTEGRATION SKELETON — not registered yet.
///
/// Steps to go live:
///  1. `flutter pub add adapty_flutter` and follow Adapty's iOS/Android setup.
///  2. In `main()` → `await Adapty().activate(configuration: AdaptyConfiguration(apiKey: '<PUBLIC_SDK_KEY>'));`
///  3. Replace each `UnimplementedError` below with the commented Adapty call.
///  4. In service_locator.dart register this class instead of
///     [MockSubscriptionRemoteDataSource].
///  5. Optional: set `AppConstants.useAdaptyPaywallBuilder = true` to render the
///     remote Paywall Builder UI (AdaptyUI) instead of the native Flutter
///     paywall; the [SubscriptionCubit] contract stays the same.
class AdaptySubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  @override
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId}) {
    // final paywall = await Adapty().getPaywall(placementId: placementId);
    // final products = await Adapty().getPaywallProducts(paywall: paywall);
    // return products.map(_toPlanModel).toList();
    throw UnimplementedError('Wire Adapty getPaywall/getPaywallProducts here.');
  }

  @override
  Future<bool> purchase(SubscriptionPlanModel plan) {
    // final result = await Adapty().makePurchase(product: _productsById[plan.vendorProductId]!);
    // return result is AdaptyPurchaseResultSuccess &&
    //     (result.profile.accessLevels[AppConstants.premiumAccessLevelId]?.isActive ?? false);
    throw UnimplementedError('Wire Adapty makePurchase here.');
  }

  @override
  Future<bool> restorePurchases() {
    // final profile = await Adapty().restorePurchases();
    // return profile.accessLevels[AppConstants.premiumAccessLevelId]?.isActive ?? false;
    throw UnimplementedError('Wire Adapty restorePurchases here.');
  }

  @override
  Future<bool> isPremiumActive() {
    // final profile = await Adapty().getProfile();
    // return profile.accessLevels[AppConstants.premiumAccessLevelId]?.isActive ?? false;
    throw UnimplementedError('Wire Adapty getProfile here.');
  }
}

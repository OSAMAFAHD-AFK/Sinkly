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
///  5. The paywall UI stays our custom Flutter screen (PaywallStepWidget) —
///     never AdaptyUI / Paywall Builder. Copy & pricing experiments can still
///     run from the dashboard via `paywall.remoteConfig` (JSON) + A/B tests,
///     as long as [logPaywallShown] is called whenever the screen appears.
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

  @override
  Future<void> logPaywallShown({required String placementId}) {
    // Required for custom (non-AdaptyUI) paywalls so analytics & A/B tests work:
    // await Adapty().logShowPaywall(paywall: _paywallsByPlacement[placementId]!);
    throw UnimplementedError('Wire Adapty logShowPaywall here.');
  }
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../../core/utils/app_constants.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';
import 'subscription_remote_data_source.dart';

/// The real subscriptions: RevenueCat in front of the App Store and Google Play.
///
/// The paywall stays our own Flutter screen. RevenueCat supplies the store
/// products (real prices in each country's currency), purchases, restore,
/// the customer's status and paywall analytics / experiments.
///
/// Dashboard setup the code expects (see store/REVENUECAT_SETUP.md):
///  * entitlement [AppConstants.premiumEntitlementId] on every product;
///  * offering `default` (current): weekly + annual packages, plus the
///    discounted annual (`annual_special`) as package
///    [AppConstants.exitOfferPackageId] — or in its own offering
///    [AppConstants.exitOfferOfferingId]; both setups work;
///  * optional placements with the ids of [AppConstants] (`*PlacementId`)
///    — used for targeting / experiments; without them the offerings above
///    are used directly.
class RevenueCatSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  final StreamController<SubscriptionStatusModel> _changes = StreamController.broadcast();

  /// The offering last shown for each placement (purchase + analytics need it).
  final Map<String, Offering> _offeringsByPlacement = {};
  final Map<String, Package> _packagesByPlanId = {};
  Future<void>? _configuring;

  static String get apiKey => Platform.isIOS ? AppConstants.revenueCatAppleApiKey : AppConstants.revenueCatGoogleApiKey;

  /// Both stores' keys are set (and we run on a phone).
  static bool get isConfigured => !kIsWeb && (Platform.isIOS || Platform.isAndroid) && apiKey.trim().isNotEmpty;

  @override
  Future<void> initialize() => _configuring ??= _configure();

  Future<void> _configure() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    // Anonymous RevenueCat customer: no accounts in Sinkly. The purchase lives
    // on the Apple / Google account, so "Restore" brings it to a new phone.
    await Purchases.configure(PurchasesConfiguration(apiKey));
    Purchases.addCustomerInfoUpdateListener((info) => _changes.add(_toStatus(info)));
  }

  // ── Paywall ────────────────────────────────────────────────────────────
  @override
  Future<List<SubscriptionPlanModel>> fetchPaywallPlans({required String placementId}) async {
    await initialize();
    final offerings = await Purchases.getOfferings();
    final offering = await _offeringFor(placementId, offerings);
    if (offering == null) throw StateError('No RevenueCat offering for placement "$placementId"');
    _offeringsByPlacement[placementId] = offering;

    final isExitOffer = placementId == AppConstants.exitOfferPlacementId;
    var packages = offering.availablePackages.where((package) => _periodOf(package) != null).toList();
    // One offering may hold both the regular plans and the exit offer's
    // discounted annual: the main paywall never shows the discounted one, the
    // exit offer shows only it.
    final discounted = packages.where(_isExitOfferPackage).toList();
    if (isExitOffer) {
      if (discounted.isNotEmpty) {
        packages = discounted;
      } else if (identical(offering, offerings.current)) {
        throw StateError('No exit-offer package (${AppConstants.exitOfferProductId}) in "${offering.identifier}"');
      }
    } else {
      packages.removeWhere(_isExitOfferPackage);
    }
    final trialEligible = await _trialEligibility(packages);

    // Reference prices for the "save X%" and exit-offer badges: the regular
    // weekly and annual plans of the main offering.
    final regular = offerings.current;
    final weekly =
        _packageWith(regular, SubscriptionPeriod.weekly) ?? _packageWith(offering, SubscriptionPeriod.weekly);
    final regularAnnual = _packageWith(regular, SubscriptionPeriod.annual);

    final plans = <SubscriptionPlanModel>[];
    for (final package in packages) {
      final product = package.storeProduct;
      final period = _periodOf(package)!;
      final planId = '${offering.identifier}:${package.identifier}';
      _packagesByPlanId[planId] = package;

      final discount = isExitOffer && period == SubscriptionPeriod.annual && regularAnnual != null
          ? _percentLess(product.price, regularAnnual.storeProduct.price)
          : null;
      plans.add(
        SubscriptionPlanModel(
          id: planId,
          vendorProductId: product.identifier,
          period: period,
          localizedPrice: product.priceString,
          localizedPricePerWeek: product.pricePerWeekString ?? product.priceString,
          trialDays: (trialEligible[product.identifier] ?? true) ? _freeTrialDays(product) : 0,
          savingVsWeeklyPercent: period != SubscriptionPeriod.weekly && weekly != null
              ? _percentLess(product.price, weekly.storeProduct.price * _weeksIn(period))
              : null,
          discountPercent: discount != null && discount > 0 ? discount : null,
          originalLocalizedPrice: discount != null && discount > 0 ? regularAnnual!.storeProduct.priceString : null,
        ),
      );
    }
    // Longest plan first (annual is the pre-selected, best-value card).
    plans.sort((a, b) => _weeksIn(b.period).compareTo(_weeksIn(a.period)));
    return plans;
  }

  /// A dashboard placement (targeting / experiments) when one is set up,
  /// otherwise the plain offering for that screen.
  Future<Offering?> _offeringFor(String placementId, Offerings offerings) async {
    try {
      final placed = await Purchases.getCurrentOfferingForPlacement(placementId);
      if (placed != null && placed.availablePackages.isNotEmpty) return placed;
    } on PlatformException {
      // No placement configured: fall back below.
    }
    return placementId == AppConstants.exitOfferPlacementId
        ? offerings.all[AppConstants.exitOfferOfferingId] ?? offerings.current
        : offerings.current;
  }

  /// iOS knows whether this Apple ID already used its free trial; Google Play
  /// only returns the trial offer to eligible customers in the first place.
  Future<Map<String, bool>> _trialEligibility(List<Package> packages) async {
    if (!Platform.isIOS || packages.isEmpty) return const {};
    try {
      final ids = packages.map((package) => package.storeProduct.identifier).toList();
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(ids);
      return result.map(
        (id, eligibility) =>
            MapEntry(id, eligibility.status != IntroEligibilityStatus.introEligibilityStatusIneligible),
      );
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> logPaywallShown({required String placementId}) async {
    if (_configuring == null) return;
    await Purchases.trackCustomPaywallImpression(
      params: CustomPaywallImpressionParams(paywallId: placementId, offering: _offeringsByPlacement[placementId]),
    );
  }

  // ── Purchase / restore / status ───────────────────────────────────────
  @override
  Future<SubscriptionStatusModel> purchase(SubscriptionPlanModel plan) async {
    await initialize();
    final package = _packagesByPlanId[plan.id];
    if (package == null) throw StateError('Unknown plan ${plan.id}');
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _toStatus(result.customerInfo);
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatusModel> restorePurchases() async {
    await initialize();
    return _toStatus(await Purchases.restorePurchases());
  }

  @override
  Future<SubscriptionStatusModel> currentStatus() async {
    await initialize();
    return _toStatus(await Purchases.getCustomerInfo());
  }

  @override
  Stream<SubscriptionStatusModel> get statusChanges => _changes.stream;

  @override
  Future<String?> customerId() async {
    await initialize();
    return Purchases.appUserID;
  }

  /// RevenueCat Customer Center (configured in the dashboard → Customer
  /// Center): plan details, cancel / change plan, restore, refund requests on
  /// iOS. Our paywall stays custom; this is only the "manage" screen.
  @override
  Future<bool> presentCustomerCenter() async {
    await initialize();
    await RevenueCatUI.presentCustomerCenter();
    // Whatever happened inside (cancel, restore…) reaches the app at once.
    _changes.add(_toStatus(await Purchases.getCustomerInfo()));
    return true;
  }

  static SubscriptionStatusModel _toStatus(CustomerInfo info) {
    final premium = info.entitlements.active[AppConstants.premiumEntitlementId];
    if (premium == null || !premium.isActive) {
      return SubscriptionStatusModel(isActive: false, managementUrl: info.managementURL);
    }
    return SubscriptionStatusModel(
      isActive: true,
      isInTrial: premium.periodType == PeriodType.trial,
      willRenew: premium.willRenew,
      expiresAt: DateTime.tryParse(premium.expirationDate ?? ''),
      productId: premium.productIdentifier,
      managementUrl: info.managementURL,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  static SubscriptionPeriod? _periodOf(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return SubscriptionPeriod.weekly;
      case PackageType.monthly:
        return SubscriptionPeriod.monthly;
      case PackageType.annual:
        return SubscriptionPeriod.annual;
      default:
        // Custom packages: read the store's ISO 8601 period (P1W, P1M, P1Y…).
        final iso = package.storeProduct.subscriptionPeriod ?? '';
        if (iso == 'P1W' || iso == 'P7D') return SubscriptionPeriod.weekly;
        if (iso == 'P1M') return SubscriptionPeriod.monthly;
        if (iso == 'P1Y' || iso == 'P12M') return SubscriptionPeriod.annual;
        return null;
    }
  }

  /// The regular plan of [period] — never the exit offer's discounted annual.
  static Package? _packageWith(Offering? offering, SubscriptionPeriod period) {
    for (final package in offering?.availablePackages ?? const <Package>[]) {
      if (_periodOf(package) == period && !_isExitOfferPackage(package)) return package;
    }
    return null;
  }

  /// The exit offer's discounted annual, by its package id or its product id
  /// (Google Play reports `annual_special:<base plan>`, hence `startsWith`).
  static bool _isExitOfferPackage(Package package) =>
      package.identifier == AppConstants.exitOfferPackageId ||
      package.storeProduct.identifier.startsWith(AppConstants.exitOfferProductId);

  static int _weeksIn(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => 1,
    SubscriptionPeriod.monthly => 4,
    SubscriptionPeriod.annual => 52,
  };

  /// How much cheaper [price] is than [reference], in whole percent.
  static int? _percentLess(double price, double reference) {
    if (reference <= 0 || price >= reference) return null;
    return ((1 - price / reference) * 100).round();
  }

  /// Length of the free trial in days, 0 when the product has none.
  static int _freeTrialDays(StoreProduct product) {
    // Google Play: the free phase of the default offer.
    final freePhase = product.defaultOption?.freePhase?.billingPeriod;
    if (freePhase != null) return _days(freePhase.unit, freePhase.value);
    // App Store: a free introductory offer.
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return _days(intro.periodUnit, intro.periodNumberOfUnits) * (intro.cycles < 1 ? 1 : intro.cycles);
    }
    return 0;
  }

  static int _days(PeriodUnit unit, int value) => switch (unit) {
    PeriodUnit.day => value,
    PeriodUnit.week => value * 7,
    PeriodUnit.month => value * 30,
    PeriodUnit.year => value * 365,
    PeriodUnit.unknown => 0,
  };
}

import 'package:equatable/equatable.dart';

enum SubscriptionPeriod { weekly, monthly, annual }

/// A purchasable plan as displayed on the paywall.
///
/// Maps 1:1 to an Adapty `AdaptyPaywallProduct` (or RevenueCat `Package`):
///  * [vendorProductId]      ← product.vendorProductId
///  * [localizedPrice]       ← product.price.localizedString (the BILLED amount)
///  * [localizedPricePerWeek]← computed from product.price.amount
///  * [trialDays]            ← product.subscription.offer (free trial phase)
///
/// Store rule (Apple 3.1.2 / Google Play): [localizedPrice] — what is actually
/// charged — must stay the most prominent price; per-week figures are
/// secondary.
class SubscriptionPlanModel extends Equatable {
  const SubscriptionPlanModel({
    required this.id,
    required this.vendorProductId,
    required this.period,
    required this.localizedPrice,
    required this.localizedPricePerWeek,
    required this.trialDays,
    this.savingVsWeeklyPercent,
    this.discountPercent,
    this.originalLocalizedPrice,
  });

  final String id;
  final String vendorProductId;
  final SubscriptionPeriod period;
  final String localizedPrice;
  final String localizedPricePerWeek;
  final int trialDays;

  /// "Save X%" ribbon on a plan card: how much cheaper this plan is than paying
  /// the weekly plan for a whole year (52 weeks).
  final int? savingVsWeeklyPercent;

  /// Extra discount vs. the regular price of the SAME plan (exit offer only:
  /// shown in its title and button).
  final int? discountPercent;

  /// Regular price shown struck through (exit offer only). Must be the real
  /// regular price of the same plan, never an invented "was" price.
  final String? originalLocalizedPrice;

  bool get hasTrial => trialDays > 0;
  bool get isBestValue => period == SubscriptionPeriod.annual;

  @override
  List<Object?> get props => [
    id,
    vendorProductId,
    period,
    localizedPrice,
    localizedPricePerWeek,
    trialDays,
    savingVsWeeklyPercent,
    discountPercent,
    originalLocalizedPrice,
  ];
}

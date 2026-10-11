import 'package:equatable/equatable.dart';

enum SubscriptionPeriod { annual, monthly }

/// A purchasable plan as displayed on the paywall.
///
/// Maps 1:1 to an Adapty `AdaptyPaywallProduct` (or RevenueCat `Package`):
///  * [vendorProductId]      ← product.vendorProductId
///  * [localizedPrice]       ← product.price.localizedString
///  * [localizedPricePerWeek]← computed from product.price.amount
///  * [trialDays]            ← product.subscription.offer (free trial phase)
class SubscriptionPlanModel extends Equatable {
  const SubscriptionPlanModel({
    required this.id,
    required this.vendorProductId,
    required this.period,
    required this.localizedPrice,
    required this.localizedPricePerWeek,
    required this.trialDays,
    this.discountPercent,
  });

  final String id;
  final String vendorProductId;
  final SubscriptionPeriod period;
  final String localizedPrice;
  final String localizedPricePerWeek;
  final int trialDays;

  /// "Save 50%" badge, shown on the annual plan.
  final int? discountPercent;

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
    discountPercent,
  ];
}

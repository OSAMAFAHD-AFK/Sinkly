import 'package:equatable/equatable.dart';

/// What the store (through RevenueCat) says about the `premium` entitlement.
class SubscriptionStatusModel extends Equatable {
  const SubscriptionStatusModel({
    required this.isActive,
    this.isInTrial = false,
    this.willRenew = false,
    this.expiresAt,
    this.productId,
    this.managementUrl,
    this.confirmed = true,
  });

  static const SubscriptionStatusModel inactive = SubscriptionStatusModel(isActive: false);

  /// Premium is unlocked right now (paid, free trial or billing grace period).
  final bool isActive;

  /// The free trial is running (nothing has been charged yet).
  final bool isInTrial;

  /// Auto-renew is still on: the user hasn't cancelled.
  final bool willRenew;

  /// End of the current period — for a trial, the moment of the first charge.
  final DateTime? expiresAt;

  final String? productId;

  /// The store's own "manage subscription" page, when the store gave one.
  final String? managementUrl;

  /// A fresh answer of the store, not an old copy kept on the phone (offline).
  /// Only a confirmed "not active" may stop the user at the paywall.
  final bool confirmed;

  /// When the first payment will be taken: only while a free trial is
  /// running AND will turn into a paid subscription. `null` otherwise (no
  /// trial, or the user already cancelled → nothing will be charged).
  DateTime? get firstChargeAt => isActive && isInTrial && willRenew ? expiresAt : null;

  @override
  List<Object?> get props => [isActive, isInTrial, willRenew, expiresAt, productId, managementUrl, confirmed];
}

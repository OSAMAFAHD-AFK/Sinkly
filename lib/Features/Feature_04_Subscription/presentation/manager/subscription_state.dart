part of 'subscription_cubit.dart';

enum SubscriptionStatus { initial, loading, ready, purchasing, restoring, failure }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.plans = const [],
    this.selectedPlanId,
    this.isPremium = false,
    this.failureKey,
    this.exitOffer,
  });

  final SubscriptionStatus status;
  final List<SubscriptionPlanModel> plans;
  final String? selectedPlanId;
  final bool isPremium;
  final String? failureKey;

  /// One-time discounted annual plan offered when leaving the paywall.
  final SubscriptionPlanModel? exitOffer;

  bool get isBusy => status == SubscriptionStatus.purchasing || status == SubscriptionStatus.restoring;

  /// [failureKey] is a notice, not an error: the store is still confirming
  /// the payment (Restore / reopening the app unlocks Premium afterwards).
  bool get failureIsNotice => failureKey == SubscriptionRepo.paymentPendingKey;

  SubscriptionPlanModel? get selectedPlan {
    for (final plan in plans) {
      if (plan.id == selectedPlanId) return plan;
    }
    return plans.isEmpty ? null : plans.first;
  }

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<SubscriptionPlanModel>? plans,
    String? selectedPlanId,
    bool? isPremium,
    String? failureKey,
    bool clearFailure = false,
    SubscriptionPlanModel? exitOffer,
  }) => SubscriptionState(
    status: status ?? this.status,
    plans: plans ?? this.plans,
    selectedPlanId: selectedPlanId ?? this.selectedPlanId,
    isPremium: isPremium ?? this.isPremium,
    failureKey: clearFailure ? null : failureKey ?? this.failureKey,
    exitOffer: exitOffer ?? this.exitOffer,
  );

  @override
  List<Object?> get props => [status, plans, selectedPlanId, isPremium, failureKey, exitOffer];
}

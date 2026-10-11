import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_constants.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/repos/subscription_repo.dart';

part 'subscription_state.dart';

/// App-wide subscription state (provided above the router). Used by the
/// onboarding paywall step, the standalone PaywallView and Settings.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repo) : super(const SubscriptionState());

  final SubscriptionRepo _repo;

  Future<void> initialize() async {
    final isPremium = await _repo.isPremiumActive();
    emit(state.copyWith(isPremium: isPremium));
  }

  Future<void> loadPaywall({String placementId = AppConstants.adaptyOnboardingPlacementId}) async {
    if (state.plans.isNotEmpty) return;
    emit(state.copyWith(status: SubscriptionStatus.loading, clearFailure: true));
    final result = await _repo.fetchPaywallPlans(placementId: placementId);
    result.fold(
      (failure) => emit(state.copyWith(status: SubscriptionStatus.failure, failureKey: failure.messageKey)),
      (plans) => emit(
        state.copyWith(
          status: SubscriptionStatus.ready,
          plans: plans,
          // Annual is pre-selected: highest LTV and the anchor of the offer.
          selectedPlanId: plans.where((plan) => plan.isBestValue).firstOrNull?.id ?? plans.firstOrNull?.id,
        ),
      ),
    );
  }

  void selectPlan(String planId) => emit(state.copyWith(selectedPlanId: planId));

  /// Returns `true` when premium is active after the purchase.
  Future<bool> purchaseSelectedPlan() async {
    final plan = state.selectedPlan;
    if (plan == null || state.isBusy) return false;
    emit(state.copyWith(status: SubscriptionStatus.purchasing, clearFailure: true));
    final result = await _repo.purchase(plan);
    return result.fold(
      (failure) {
        emit(state.copyWith(status: SubscriptionStatus.ready, failureKey: failure.messageKey));
        return false;
      },
      (isPremium) {
        emit(state.copyWith(status: SubscriptionStatus.ready, isPremium: isPremium));
        return isPremium;
      },
    );
  }

  Future<bool> restorePurchases() async {
    if (state.isBusy) return false;
    emit(state.copyWith(status: SubscriptionStatus.restoring, clearFailure: true));
    final result = await _repo.restorePurchases();
    return result.fold(
      (failure) {
        emit(state.copyWith(status: SubscriptionStatus.ready, failureKey: failure.messageKey));
        return false;
      },
      (isPremium) {
        emit(
          state.copyWith(
            status: SubscriptionStatus.ready,
            isPremium: isPremium,
            failureKey: isPremium ? null : 'restore_nothing_found',
          ),
        );
        return isPremium;
      },
    );
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));
}

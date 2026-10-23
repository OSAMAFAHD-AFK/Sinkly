import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_constants.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/repos/subscription_repo.dart';

part 'subscription_state.dart';

/// App-wide subscription state (provided above the router). Used by the
/// onboarding paywall step, the standalone PaywallView and Settings.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repo) : super(const SubscriptionState());

  final SubscriptionRepo _repo;
  StreamSubscription<bool>? _premiumChanges;

  Future<void> initialize() async {
    // Renewals, cancellations, refunds… reported by the store while the app runs.
    _premiumChanges ??= _repo.premiumChanges.listen((isPremium) {
      if (!isClosed && isPremium != state.isPremium) emit(state.copyWith(isPremium: isPremium));
    });
    final isPremium = await _repo.isPremiumActive();
    if (!isClosed) emit(state.copyWith(isPremium: isPremium));
  }

  /// [force]: ask the store again even if plans are already loaded (the paywall
  /// opens again later: the free trial may no longer be on offer).
  Future<void> loadPaywall({String placementId = AppConstants.onboardingPaywallPlacementId, bool force = false}) async {
    if (state.plans.isNotEmpty && !force) return;
    if (state.isBusy) return;
    // Plans already on screen stay while the fresh ones load (no flicker).
    emit(state.copyWith(status: state.plans.isEmpty ? SubscriptionStatus.loading : state.status, clearFailure: true));
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

  /// Call whenever the custom paywall becomes visible (RevenueCat analytics).
  void paywallShown({String placementId = AppConstants.onboardingPaywallPlacementId}) =>
      _repo.logPaywallShown(placementId: placementId);

  void selectPlan(String planId) => emit(state.copyWith(selectedPlanId: planId));

  // ── Paywall exit offer (opens every time the user taps "X") ─────────────
  /// Preloads the discounted plan so the sheet opens instantly.
  Future<void> loadExitOffer({bool force = false}) async {
    if (state.exitOffer != null && !force) return;
    final result = await _repo.fetchPaywallPlans(placementId: AppConstants.exitOfferPlacementId);
    if (isClosed) return;
    result.fold((_) {}, (plans) {
      if (plans.isNotEmpty) emit(state.copyWith(exitOffer: plans.first));
    });
  }

  /// Call when the exit-offer sheet appears (RevenueCat analytics).
  void exitOfferShown() {
    _repo.logPaywallShown(placementId: AppConstants.exitOfferPlacementId);
  }

  Future<bool> purchaseExitOffer() async {
    final offer = state.exitOffer;
    return offer == null ? false : _purchase(offer);
  }

  /// Returns `true` when premium is active after the purchase.
  Future<bool> purchaseSelectedPlan() async {
    final plan = state.selectedPlan;
    return plan == null ? false : _purchase(plan);
  }

  Future<bool> _purchase(SubscriptionPlanModel plan) async {
    if (state.isBusy) return false;
    emit(state.copyWith(status: SubscriptionStatus.purchasing, clearFailure: true));
    final result = await _repo.purchase(plan);
    return result.fold(
      (failure) {
        // Closing the store sheet is a choice, not an error: no message.
        final cancelled = failure is PurchaseFailure && failure.userCancelled;
        emit(state.copyWith(status: SubscriptionStatus.ready, failureKey: cancelled ? null : failure.messageKey));
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

  /// The store page where the subscription is managed or cancelled.
  Future<String> manageSubscriptionUrl() => _repo.manageSubscriptionUrl();

  /// RevenueCat Customer Center; `false` → use [manageSubscriptionUrl].
  Future<bool> openCustomerCenter() => _repo.openCustomerCenter();

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() {
    _premiumChanges?.cancel();
    return super.close();
  }
}

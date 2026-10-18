import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../Feature_06_SinkUnlock/data/repos/app_blocking_repo.dart';
import '../data_sources/subscription_remote_data_source.dart';
import '../models/subscription_plan_model.dart';
import 'subscription_repo.dart';

class SubscriptionRepoImpl implements SubscriptionRepo {
  SubscriptionRepoImpl(this._remote, this._blocking);

  final SubscriptionRemoteDataSource _remote;

  /// Locking runs only while the subscription is active (user decision):
  /// every fresh answer from the store is passed on.
  final AppBlockingRepo _blocking;

  @override
  Future<Either<Failure, List<SubscriptionPlanModel>>> fetchPaywallPlans({required String placementId}) async {
    try {
      return right(await _remote.fetchPaywallPlans(placementId: placementId));
    } catch (error) {
      return left(ServerFailure('error_paywall_load', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> purchase(SubscriptionPlanModel plan) async {
    try {
      final isPremium = await _remote.purchase(plan);
      if (isPremium) await _blocking.setSubscriptionActive(true);
      return right(isPremium);
    } catch (error) {
      // Map provider-specific "user cancelled" errors here (Adapty: AdaptyErrorCode.paymentCancelled).
      return left(PurchaseFailure('error_purchase', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> restorePurchases() async {
    try {
      final isPremium = await _remote.restorePurchases();
      await _blocking.setSubscriptionActive(isPremium);
      return right(isPremium);
    } catch (error) {
      return left(PurchaseFailure('error_restore', debugMessage: '$error'));
    }
  }

  @override
  Future<bool> isPremiumActive() async {
    try {
      final isPremium = await _remote.isPremiumActive();
      await _blocking.setSubscriptionActive(isPremium);
      return isPremium;
    } catch (_) {
      // Unknown (e.g. offline): keep the blocker's last known state.
      return false;
    }
  }

  @override
  Future<void> logPaywallShown({required String placementId}) async {
    try {
      await _remote.logPaywallShown(placementId: placementId);
    } catch (_) {
      // Analytics must never block the paywall.
    }
  }
}

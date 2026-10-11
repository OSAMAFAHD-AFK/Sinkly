import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../data_sources/subscription_remote_data_source.dart';
import '../models/subscription_plan_model.dart';
import 'subscription_repo.dart';

class SubscriptionRepoImpl implements SubscriptionRepo {
  SubscriptionRepoImpl(this._remote);

  final SubscriptionRemoteDataSource _remote;

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
      return right(await _remote.purchase(plan));
    } catch (error) {
      // Map provider-specific "user cancelled" errors here (Adapty: AdaptyErrorCode.paymentCancelled).
      return left(PurchaseFailure('error_purchase', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> restorePurchases() async {
    try {
      return right(await _remote.restorePurchases());
    } catch (error) {
      return left(PurchaseFailure('error_restore', debugMessage: '$error'));
    }
  }

  @override
  Future<bool> isPremiumActive() async {
    try {
      return await _remote.isPremiumActive();
    } catch (_) {
      return false;
    }
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/subscription_plan_model.dart';

abstract class SubscriptionRepo {
  Future<Either<Failure, List<SubscriptionPlanModel>>> fetchPaywallPlans({required String placementId});
  Future<Either<Failure, bool>> purchase(SubscriptionPlanModel plan);
  Future<Either<Failure, bool>> restorePurchases();
  Future<bool> isPremiumActive();
  Future<void> logPaywallShown({required String placementId});
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/subscription_plan_model.dart';

abstract class SubscriptionRepo {
  /// Failure key of a purchase the store still has to confirm: a notice, not
  /// an error (Premium turns on by itself once the payment goes through).
  static const String paymentPendingKey = 'purchase_pending';

  /// Connects to the store and keeps the app in step with every status
  /// change (renewal, cancellation, refund…): app locking runs only while
  /// subscribed, and the "trial ends tomorrow" reminder follows the trial.
  Future<void> start();

  Future<Either<Failure, List<SubscriptionPlanModel>>> fetchPaywallPlans({required String placementId});

  /// `Right(true)` when Premium is active after the purchase. Closing the
  /// store sheet is `Left(PurchaseFailure(userCancelled: true))`.
  Future<Either<Failure, bool>> purchase(SubscriptionPlanModel plan);

  Future<Either<Failure, bool>> restorePurchases();

  Future<bool> isPremiumActive();

  /// Premium switched on / off (purchase, expiry, refund…) while the app runs.
  Stream<bool> get premiumChanges;

  Future<void> logPaywallShown({required String placementId});

  /// The store's own page where the user manages or cancels the subscription.
  Future<String> manageSubscriptionUrl();

  /// RevenueCat's Customer Center; `false` → open [manageSubscriptionUrl].
  Future<bool> openCustomerCenter();
}

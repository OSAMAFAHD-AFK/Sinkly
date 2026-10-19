/// Sinkly's local reminders, kept in step with the app automatically:
///
///  * **Next lock** — 15 minutes before each planned lock (the end of a meal):
///    "Apps lock at 2:00 PM". Re-planned whenever the plan, the language or
///    the subscription changes and whenever Sinkly comes back to the front.
///  * **Free trial ends** — once, 24 hours before the first charge, only while
///    the trial will really turn into a payment (cancelled → removed).
///
/// Both follow the "Reminders" switch in Settings and need the system
/// notification permission (asked during onboarding).
abstract class RemindersRepo {
  /// Starts listening and plans the reminders. Call once at launch.
  Future<void> start();

  /// The store said when the free trial turns into the first payment
  /// (`null`: no renewing trial — any pending trial reminder is removed).
  Future<void> setTrialChargeAt(DateTime? chargeAt);

  /// Re-plans everything now (plan saved, app resumed, …).
  Future<void> refresh();
}

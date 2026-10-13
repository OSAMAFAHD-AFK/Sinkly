/// App-wide constants and integration switches.
abstract final class AppConstants {
  static const String appName = 'Sinkly';
  static const String appVersion = '0.1.0';

  // ── Core mechanic ──────────────────────────────────────────────────────
  /// The guided "sink sprint" length (default; users can adjust it).
  static const Duration sinkSprintDuration = Duration(minutes: 5);

  /// Bounds and quick picks for the user-adjustable sprint timer (minutes).
  static const int minSprintMinutes = 1;
  static const int maxSprintMinutes = 30;
  static const List<int> sprintPresetMinutes = [3, 5, 7, 10, 15, 20];

  /// Avoidance time lost per day according to onboarding research copy.
  static const double averageHoursLostPerDay = 1.5;

  /// Avoidance-scrolling time we estimate each clean sink saves.
  /// (2 meals/day × 7 days × 30 min ≈ the 7 h/week promised in onboarding.)
  static const int minutesReclaimedPerClean = 30;

  /// "Mom Points" earned for every clean sink (introduced on the Welcome
  /// screen; the points system itself is part of the in-app phase).
  static const int momPointsPerClean = 10;

  // ── Subscription / Adapty ─────────────────────────────────────────────
  static const int freeTrialDays = 3;

  // PRODUCT DECISION: the paywall is ALWAYS our custom Flutter screen (with
  // the heroine). Adapty only supplies products/prices, purchases, restore and
  // analytics — its built-in Paywall Builder UI (AdaptyUI) is never used.

  /// When `true`, onboarding is rendered by Adapty Onboarding Builder.
  static const bool useAdaptyOnboardingBuilder = false;

  /// Adapty placement ids (configure the same ids in the Adapty dashboard).
  static const String adaptyOnboardingPlacementId = 'onboarding_paywall';
  static const String adaptySettingsPlacementId = 'settings_upgrade';
  static const String adaptyOnboardingFlowPlacementId = 'onboarding_flow';

  /// Discounted annual plan offered every time the user taps "X" on the
  /// paywall (a separate product: `sinkly_premium_annual_special`).
  static const String adaptyExitOfferPlacementId = 'paywall_exit_offer';

  /// Access level granted by an active subscription.
  static const String premiumAccessLevelId = 'premium';

  // ── Remote API (future) ───────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.sinkly.app/v1/';

  // ── Legal ──────────────────────────────────────────────────────────────
  static const String termsUrl = 'https://sinkly.app/terms';
  static const String privacyUrl = 'https://sinkly.app/privacy';
  static const String supportEmail = 'support@sinkly.app';
}

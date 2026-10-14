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

  // ── Store / sharing ────────────────────────────────────────────────────
  /// TODO(store): the numeric Apple ID from App Store Connect (App
  /// Information → Apple ID). Needed on iOS to open the store review page
  /// when the native prompt is unavailable. Empty until the app is created.
  static const String appStoreId = '';

  /// Android package (Google Play listing id) = `applicationId` in Gradle.
  static const String androidPackageName = 'com.sinkly.sinkly';

  /// TODO(store): ONE smart link for invites that sends iPhone users to the
  /// App Store and Android users to Google Play (e.g. a tiny redirect page
  /// on sinkly.app, or a Firebase Dynamic Link replacement such as Branch).
  /// `ref=invite` lets the store / analytics attribute installs to sharing.
  static const String inviteLink = 'https://sinkly.app/get?ref=invite';

  // ── Development ────────────────────────────────────────────────────────
  /// TODO(dev): shows a "bypass" button on the lock overlay so it can be
  /// tested without cleaning. MUST be `false` (and removed) before release.
  static const bool showDevLockBypass = true;

  /// TODO(dev): shows "Skip to Welcome" on the first onboarding screen so the
  /// whole setup can be skipped while designing. MUST be removed before
  /// release.
  static const bool showDevOnboardingSkip = true;

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

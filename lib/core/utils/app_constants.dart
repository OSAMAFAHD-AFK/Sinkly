/// App-wide constants and integration switches.
abstract final class AppConstants {
  static const String appName = 'Sinkly';

  /// Keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

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
  /// The numeric Apple ID from App Store Connect (App Information → Apple
  /// ID). Opens the store review page on iOS when the native prompt is
  /// unavailable.
  static const String appStoreId = '6824015468';

  /// Android package (Google Play listing id) = `applicationId` in Gradle.
  static const String androidPackageName = 'com.sinkly.app';

  /// Sinkly's website (legal pages, support, invite redirect): `site/` in
  /// this repo, published on the owner's domain.
  static const String websiteUrl = 'https://sinkly.osamafahd.com';

  /// ONE link for invites: the page sends iPhone users to the App Store and
  /// Android users to Google Play (`site/get/index.html`).
  /// `ref=invite` lets the store / analytics attribute installs to sharing.
  static const String inviteLink = '$websiteUrl/get/?ref=invite';

  // ── Subscription / RevenueCat ─────────────────────────────────────────
  /// Shown before the store answers; the real length comes from the store.
  static const int freeTrialDays = 3;

  // PRODUCT DECISION: the paywall is ALWAYS our custom Flutter screen (with
  // the heroine). RevenueCat only supplies products/prices, purchases,
  // restore, status and analytics — never its own paywall UI.

  /// RevenueCat → Project settings → API keys → the PUBLIC app-specific keys
  /// (`appl_…` / `goog_…`). Public by design: they ship inside the app.
  /// While empty the app keeps the offline mock subscription.
  static const String revenueCatAppleApiKey = '';
  static const String revenueCatGoogleApiKey = '';

  /// Entitlement unlocked by every Sinkly product (RevenueCat dashboard).
  static const String premiumEntitlementId = 'premium';

  /// Paywall placements (optional RevenueCat placements with the same ids
  /// enable targeting / price experiments per screen).
  static const String onboardingPaywallPlacementId = 'onboarding_paywall';
  static const String settingsPaywallPlacementId = 'settings_upgrade';

  /// Discounted annual plan offered every time the user taps "X" on the
  /// paywall: its own offering, product `sinkly_premium_annual_special`.
  static const String exitOfferPlacementId = 'paywall_exit_offer';
  static const String exitOfferOfferingId = 'exit_offer';

  /// The store pages where a subscription is managed / cancelled.
  static const String appleSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
  static const String googleSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions?package=$androidPackageName';

  // ── Supabase (photo check + feedback only; everything else is on-device) ─
  /// TODO(supabase): Project Settings → "Project URL" and API Keys →
  /// "Publishable key" (sb_publishable_…; the legacy "anon" key also works).
  /// Both are MEANT to be public (they ship inside every app);
  /// safety comes from Row Level Security + the Edge Function's limits.
  /// The Gemini key is NOT here: it lives only in Supabase secrets.
  /// While either is empty the app keeps using the offline mocks.
  static const String supabaseUrl = 'https://mihskiwblvfzgqutkqlr.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_ZKjgUhtGRlId5nFBmSXr2Q_ow6QYz4F';

  /// Edge Function that checks the clean-sink photo with Gemini.
  static const String verifySinkPhotoFunction = 'verify-sink-photo';

  /// Long side of the photo sent for checking: enough for the model, cheap
  /// in tokens and fast to upload.
  static const int verificationPhotoMaxSide = 1024;

  /// Mirrors the server limits (supabase/functions + migration) so the app
  /// can explain them without a round trip.
  static const int verificationDailyLimit = 15;
  static const int feedbackDailyLimit = 5;

  // ── Legal ──────────────────────────────────────────────────────────────
  static const String termsUrl = '$websiteUrl/terms/';
  static const String privacyUrl = '$websiteUrl/privacy/';
  static const String supportUrl = '$websiteUrl/support/';
  static const String supportEmail = 'osamadeveloper0@gmail.com';
}

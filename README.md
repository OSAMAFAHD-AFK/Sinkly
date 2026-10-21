# Sinkly

**Clean sink. Clear mind.** After each meal, Sinkly pauses the distracting apps you chose. A photo of your clean sink (checked by AI) brings them back.

Flutter app for **iOS** and **Android**, 10 languages (English, العربية, Deutsch, Español, Français, Italiano, Português, 日本語, 한국어, हिन्दी), no accounts.

- Website, privacy policy and terms: <https://sinkly.osamafahd.com> (source in [`docs/`](docs), published with GitHub Pages)
- Bundle ID / package: `com.sinkly.app`

## How it works

| Piece | Where | What it does |
|---|---|---|
| The lock rule | `lib/core/models/lock_status_model.dart` | One pure rule: a lock starts when a planned meal ends and lasts until a clean-sink photo is accepted. Re-implemented identically in Kotlin and Swift and checked against the same cases (`test/fixtures/lock_engine_vectors.json`). |
| Android blocker | `android/app/src/main/kotlin/com/sinkly/app/blocking/` | Foreground service + usage access, shows the lock card over a locked app. |
| iPhone blocker | `ios/Shared`, `ios/Sinkly*Extension`, `ios/SinklyShield*` | Apple Screen Time (FamilyControls / ManagedSettings / DeviceActivity) with a branded shield. Setup on a Mac: [`ios/BLOCKING_SETUP.md`](ios/BLOCKING_SETUP.md). |
| Photo check | `supabase/functions/verify-sink-photo` | Edge Function → Gemini. The photo is never stored. 15 checks per phone per day; subscribers only (RevenueCat). See [`supabase/README.md`](supabase/README.md). |
| Subscriptions | `lib/Features/Feature_04_Subscription` | RevenueCat (mock until the keys are set). Custom Flutter paywall, never RevenueCat's UI. |
| Reminders | `lib/Features/Feature_11_Reminders` | Local notifications only (no server): next lock, free-trial end. |
| Crash reports | `lib/core/utils/crash_reporting_service.dart` | Firebase Crashlytics (release builds only). |

## Project layout

```
lib/
  core/                      errors, models, utils, shared widgets
  Features/Feature_NN_Name/  data/{data_sources,models,repos} + presentation/{manager,views}
assets/translations/         one JSON per language (every key must exist in all 10)
assets/google_fonts/         Cairo + Plus Jakarta Sans, bundled (SIL OFL)
supabase/                    migrations + the Edge Function
docs/                        public website + legal pages
store/                       store listing texts, form answers, RevenueCat setup
```

State management is `flutter_bloc` (Cubits), DI is `get_it`, routing is `go_router`.

## Run

```bash
flutter pub get
flutter run                 # Android or iPhone (blocking needs a real device)
flutter analyze
flutter test                # includes a layout audit on 5 screen sizes, EN + AR
```

Android native tests of the lock rule:

```bash
cd android && ./gradlew :app:testDebugUnitTest
```

## Configuration

Everything public lives in `lib/core/utils/app_constants.dart` (Supabase URL and *publishable* key, RevenueCat public keys, store IDs, legal URLs). **Secrets are never in the repo or the app:**

| Secret | Where it lives |
|---|---|
| Gemini API key | Supabase secret `GEMINI_API_KEY` |
| RevenueCat secret key | Supabase secret `REVENUECAT_SECRET_KEY` |
| Android upload keystore + passwords | `android/key.properties` and `android/app/*.jks` (git-ignored) |

## Release checklist

1. RevenueCat keys: debug builds use the Test Store key (`test_…`), release builds the real `appl_…` / `goog_…`
   (see `AppConstants`) — the SDK rejects a `test_` key in a release build. Empty keys → the offline mock, which unlocks
   Premium without paying: never publish with that. Deploy the photo check: `npx supabase functions deploy verify-sink-photo`.
2. Check the photo check is live (`supabaseUrl` / `supabasePublishableKey`): release builds never approve photos offline.
3. Bump `version:` in `pubspec.yaml` (and `AppConstants.appVersion`).
4. Android: `flutter build appbundle` (signed with the upload key).
5. iOS: archive in Xcode (see `ios/BLOCKING_SETUP.md`).

Store texts and form answers: [`store/STORE_LISTING.md`](store/STORE_LISTING.md), [`store/STORE_FORMS.md`](store/STORE_FORMS.md), [`store/REVENUECAT_SETUP.md`](store/REVENUECAT_SETUP.md).

## Notes

- Any change to the lock screen design in Flutter must be mirrored in Kotlin (`LockCoverOverlay.kt`) and in the iPhone shield texts.
- Any new text needs a key in **all 10** translation files.
- The iPhone code has been written but not yet built or run on a device.

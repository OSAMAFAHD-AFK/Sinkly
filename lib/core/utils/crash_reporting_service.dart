import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics: every crash on a user's phone reaches the Firebase
/// console (stack trace, phone model, OS version, app version) — no personal
/// data, no photos, no account.
///
/// Turns itself on once the Firebase config files exist
/// (`flutterfire configure`: android/app/google-services.json +
/// ios/Runner/GoogleService-Info.plist). Until then, and in debug runs, it
/// stays off without affecting the app.
abstract final class CrashReportingService {
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static Future<void> initialize() async {
    if (kDebugMode || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await Firebase.initializeApp();
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      // Flutter framework errors (build / layout / paint).
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      // Everything else (async errors, platform channels…).
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      _enabled = true;
    } catch (error) {
      // Not configured yet: the app works exactly the same without it.
      debugPrint('[Crashlytics] off: $error');
    }
  }

  /// A handled problem worth knowing about (never shown to the user).
  static void recordError(Object error, StackTrace? stack, {String? reason}) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }
}

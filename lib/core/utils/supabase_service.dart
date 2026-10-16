import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_constants.dart';

/// Thrown when Supabase can't be reached or isn't set up yet.
class SupabaseUnavailableException implements Exception {
  const SupabaseUnavailableException({required this.isOffline, this.debugMessage});

  /// True for "no internet / timeout" (worth retrying later).
  final bool isOffline;
  final String? debugMessage;

  @override
  String toString() => 'SupabaseUnavailableException(offline: $isOffline, $debugMessage)';
}

/// The app's only door to Supabase (photo check + feedback).
///
/// There are no accounts: the first time Supabase is needed, the phone signs
/// in anonymously (no screen, no email). That hidden identity is what the
/// server uses to apply its limits (15 photo checks and 5 ideas per day).
class SupabaseService {
  bool _initialized = false;
  Future<User>? _signingIn;

  bool get isConfigured => AppConstants.supabaseUrl.isNotEmpty && AppConstants.supabasePublishableKey.isNotEmpty;

  /// Restores a saved session from disk. Needs no internet.
  Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    try {
      await Supabase.initialize(url: AppConstants.supabaseUrl, publishableKey: AppConstants.supabasePublishableKey);
      _initialized = true;
    } catch (error) {
      // Never block app start: the photo check reports "unavailable" instead.
      debugPrint('[Supabase] init failed: $error');
    }
  }

  /// A client holding a valid anonymous session.
  /// Throws [SupabaseUnavailableException] when offline or not configured.
  Future<SupabaseClient> authenticatedClient() async {
    if (!_initialized) throw const SupabaseUnavailableException(isOffline: false, debugMessage: 'not configured');
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) return client;
    try {
      // One sign-in even if several callers ask at the same moment.
      await (_signingIn ??= _signInAnonymously(client));
      return client;
    } catch (error) {
      throw SupabaseUnavailableException(isOffline: isOfflineError(error), debugMessage: '$error');
    } finally {
      _signingIn = null;
    }
  }

  /// Called when the server refused the session's token.
  ///
  /// First refreshes it (same user, so the daily limits keep counting). Only
  /// if the user no longer exists on the server (e.g. deleted in the
  /// dashboard) does the phone start a new anonymous identity.
  /// Throws like [authenticatedClient].
  Future<SupabaseClient> renewSession() async {
    if (!_initialized) throw const SupabaseUnavailableException(isOffline: false, debugMessage: 'not configured');
    final client = Supabase.instance.client;
    try {
      await client.auth.refreshSession();
      return client;
    } on AuthException catch (error) {
      if (error is AuthRetryableFetchException) {
        throw SupabaseUnavailableException(isOffline: true, debugMessage: '$error');
      }
      // Refresh token refused: the old identity is gone for good.
    } catch (error) {
      throw SupabaseUnavailableException(isOffline: isOfflineError(error), debugMessage: '$error');
    }
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    return authenticatedClient();
  }

  Future<User> _signInAnonymously(SupabaseClient client) async {
    final response = await client.auth.signInAnonymously().timeout(const Duration(seconds: 15));
    final user = response.user;
    if (user == null) throw const AuthException('anonymous sign-in returned no user');
    return user;
  }

  /// Network trouble (as opposed to a real server answer).
  static bool isOfflineError(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException;
}

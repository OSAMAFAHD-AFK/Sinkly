import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/supabase_service.dart';
import '../models/sink_photo_verification_result_model.dart';

/// Decides whether a photo shows a clean sink.
///
/// Production: [SupabaseSinkPhotoVerificationDataSource] → Edge Function
/// `verify-sink-photo` → Gemini (the API key never touches the phone).
/// Desktop / tests / not-yet-configured builds: [MockSinkPhotoVerificationDataSource].
abstract class SinkPhotoVerificationDataSource {
  /// A non-clean photo is a normal result (`isClean: false` + `reasonKey`).
  /// Throws [VerificationUnavailableException] when the check itself couldn't run.
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath);
}

/// The check couldn't run (offline, daily limit, service down…). [messageKey]
/// is the translation key shown to the user.
class VerificationUnavailableException implements Exception {
  const VerificationUnavailableException(this.messageKey, {this.debugMessage});

  final String messageKey;
  final String? debugMessage;

  @override
  String toString() => 'VerificationUnavailableException($messageKey, $debugMessage)';
}

class SupabaseSinkPhotoVerificationDataSource implements SinkPhotoVerificationDataSource {
  SupabaseSinkPhotoVerificationDataSource(this._supabase, {required Future<String?> Function() customerId})
    : _customerId = customerId;

  // ignore_for_file: prefer_initializing_formals — named parameters keep call sites readable.
  final SupabaseService _supabase;

  /// RevenueCat customer id: the server asks RevenueCat itself whether this
  /// customer is subscribed before spending a Gemini check.
  final Future<String?> Function() _customerId;

  /// Same ceiling as the Edge Function (`MAX_IMAGE_BYTES`).
  static const int _maxPhotoBytes = 700000;

  @override
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath) async {
    final bytes = await File(photoPath).readAsBytes();
    if (bytes.isEmpty || bytes.length > _maxPhotoBytes) {
      throw VerificationUnavailableException('verify_error_unreadable', debugMessage: '${bytes.length} bytes');
    }

    final body = {'image': base64Encode(bytes), 'customer_id': await _safeCustomerId() ?? ''};
    try {
      FunctionResponse response;
      try {
        response = await _invoke(await _supabase.authenticatedClient(), body);
      } on FunctionException catch (error) {
        if (error.status != 401) rethrow;
        // The saved session isn't accepted any more: start a fresh one, once.
        response = await _invoke(await _supabase.renewSession(), body);
      }
      return _toResult(response.data);
    } on SupabaseUnavailableException catch (error) {
      throw VerificationUnavailableException(
        error.isOffline ? 'error_no_internet' : 'verify_error_unavailable',
        debugMessage: error.debugMessage,
      );
    } on FunctionException catch (error) {
      throw VerificationUnavailableException(
        _keyForStatus(error.status),
        debugMessage: '${error.status} ${error.details}',
      );
    } catch (error) {
      if (error is VerificationUnavailableException) rethrow;
      if (error is TimeoutException) throw VerificationUnavailableException('error_timeout', debugMessage: '$error');
      final offline = SupabaseService.isOfflineError(error);
      throw VerificationUnavailableException(
        offline ? 'error_no_internet' : 'verify_error_unavailable',
        debugMessage: '$error',
      );
    }
  }

  Future<String?> _safeCustomerId() async {
    try {
      return await _customerId();
    } catch (_) {
      return null; // The server decides; a missing id never crashes the check.
    }
  }

  Future<FunctionResponse> _invoke(SupabaseClient client, Map<String, String> body) =>
      client.functions.invoke(AppConstants.verifySinkPhotoFunction, body: body).timeout(const Duration(seconds: 45));

  /// `{clean: bool, reason: String}` from the Edge Function.
  SinkPhotoVerificationResultModel _toResult(Object? data) {
    final json = data is String ? jsonDecode(data) : data;
    if (json is! Map || json['clean'] is! bool) {
      throw VerificationUnavailableException('verify_error_unavailable', debugMessage: 'unexpected reply: $data');
    }
    final clean = json['clean'] as bool;
    final reason = json['reason'] as String? ?? 'unclear';
    return SinkPhotoVerificationResultModel(
      isClean: clean,
      // The model answers yes/no, so confidence is all-or-nothing.
      confidence: clean ? 1 : 0,
      reasonKey: clean ? null : _keyForReason(reason),
    );
  }

  static String _keyForReason(String reason) => switch (reason) {
    'dishes' => 'verify_error_dishes',
    'dirt' => 'verify_error_dirt',
    'no_sink' => 'verify_error_no_sink',
    'not_real_photo' => 'verify_error_not_real_photo',
    'unclear' => 'verify_error_unclear',
    _ => 'verify_error_not_clean',
  };

  static String _keyForStatus(int status) => switch (status) {
    429 => 'verify_error_limit_reached',
    402 => 'verify_error_subscription',
    400 || 413 => 'verify_error_unreadable',
    _ => 'verify_error_unavailable',
  };
}

/// A store build without the photo-check backend: no photo is approved; the
/// user sees "couldn't check your photo right now" instead of a free unlock.
class UnavailableSinkPhotoVerificationDataSource implements SinkPhotoVerificationDataSource {
  const UnavailableSinkPhotoVerificationDataSource();

  @override
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath) async =>
      const SinkPhotoVerificationResultModel(isClean: false, confidence: 0, reasonKey: 'verify_error_unavailable');
}

class MockSinkPhotoVerificationDataSource implements SinkPhotoVerificationDataSource {
  @override
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath) async {
    // Lets the scanning animation play for a satisfying moment.
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    final exists = await File(photoPath).exists();
    return exists
        ? const SinkPhotoVerificationResultModel(isClean: true, confidence: 0.94)
        : const SinkPhotoVerificationResultModel(isClean: false, confidence: 0, reasonKey: 'verify_error_unreadable');
  }
}

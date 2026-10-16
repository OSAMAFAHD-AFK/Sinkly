import 'dart:io' show Platform;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/supabase_service.dart';

/// Why one queued idea couldn't be delivered.
enum FeedbackSendError {
  /// No internet / Supabase not reachable or not set up: keep it, retry later.
  unavailable,

  /// The server refused it for good (daily limit, invalid data): drop it.
  rejected,
}

class FeedbackSendException implements Exception {
  const FeedbackSendException(this.error, {this.debugMessage});

  final FeedbackSendError error;
  final String? debugMessage;

  @override
  String toString() => 'FeedbackSendException($error, $debugMessage)';
}

/// Delivers suggestions to the Supabase `feedback` table (insert-only; the
/// database itself enforces 5 ideas per phone per day).
abstract class FeedbackRemoteDataSource {
  /// [payload] is a stored `UserFeedbackModel.toJson()`.
  Future<void> send(Map<String, dynamic> payload);
}

class SupabaseFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  SupabaseFeedbackRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  /// Postgres "unique violation": this idea already arrived on an earlier try.
  static const String _alreadySent = '23505';

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    final row = {
      'client_id': payload['id'],
      'category': payload['category'],
      'message': payload['message'],
      'language_code': payload['languageCode'],
      'app_version': payload['appVersion'],
      'platform': Platform.isIOS ? 'ios' : 'android',
    };
    try {
      try {
        // Insert only — no `.select()`: phones are not allowed to read the table.
        await (await _supabase.authenticatedClient()).from('feedback').insert(row);
      } on PostgrestException catch (error) {
        // PGRST3xx = the session's token was refused: start a fresh one, once.
        if (!(error.code ?? '').startsWith('PGRST3')) rethrow;
        await (await _supabase.renewSession()).from('feedback').insert(row);
      }
    } on SupabaseUnavailableException catch (error) {
      throw FeedbackSendException(FeedbackSendError.unavailable, debugMessage: error.debugMessage);
    } on PostgrestException catch (error) {
      if (error.code == _alreadySent) return;
      throw FeedbackSendException(FeedbackSendError.rejected, debugMessage: '${error.code} ${error.message}');
    } catch (error) {
      throw FeedbackSendException(FeedbackSendError.unavailable, debugMessage: '$error');
    }
  }
}

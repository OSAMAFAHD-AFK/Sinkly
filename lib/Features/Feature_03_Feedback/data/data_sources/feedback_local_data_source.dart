import 'dart:convert';

import '../../../../core/utils/local_storage_service.dart';
import '../models/user_feedback_model.dart';

/// On-device side of suggestions:
///  * an outbox, so an idea written offline is sent later
///    (`FeedbackRemoteDataSource` → Supabase `feedback` table);
///  * a log of send times, so the daily limit is explained instantly.
abstract class FeedbackLocalDataSource {
  Future<void> saveFeedback(UserFeedbackModel feedback);
  List<String> pendingFeedbackPayloads();
  Future<void> removePending(String feedbackId);

  /// Ideas submitted in the last [window] (sent or still waiting).
  int submissionsWithin(Duration window, {required DateTime now});
}

class FeedbackLocalDataSourceImpl implements FeedbackLocalDataSource {
  FeedbackLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;
  static const String _outboxKey = 'sinkly.feedback_outbox';
  static const String _submissionLogKey = 'sinkly.feedback_submitted_at';

  @override
  Future<void> saveFeedback(UserFeedbackModel feedback) async {
    // Small delay keeps the "sending" state visible — feels intentional.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _storage.setStringList(_outboxKey, [...pendingFeedbackPayloads(), jsonEncode(feedback.toJson())]);
    final recent = _submissionTimes().where((time) => feedback.createdAt.difference(time) < const Duration(days: 1));
    await _storage.setStringList(_submissionLogKey, [
      ...recent.map((time) => time.toIso8601String()),
      feedback.createdAt.toIso8601String(),
    ]);
  }

  @override
  List<String> pendingFeedbackPayloads() => _storage.getStringList(_outboxKey);

  @override
  Future<void> removePending(String feedbackId) => _storage.setStringList(
    _outboxKey,
    pendingFeedbackPayloads().where((payload) => _idOf(payload) != feedbackId).toList(),
  );

  @override
  int submissionsWithin(Duration window, {required DateTime now}) =>
      _submissionTimes().where((time) => now.difference(time) < window).length;

  List<DateTime> _submissionTimes() =>
      _storage.getStringList(_submissionLogKey).map(DateTime.tryParse).whereType<DateTime>().toList();

  static String? _idOf(String payload) {
    try {
      return (jsonDecode(payload) as Map)['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';

import '../../../../core/utils/local_storage_service.dart';
import '../models/user_feedback_model.dart';

/// Stores suggestions on-device for now (outbox).
///
/// Next step: add `FeedbackRemoteDataSource` writing to Firestore
/// (`feedback` collection) or `ApiService.post(endPoint: 'feedback')`, and let
/// the repo flush this outbox when online.
abstract class FeedbackLocalDataSource {
  Future<void> saveFeedback(UserFeedbackModel feedback);
  List<String> pendingFeedbackPayloads();
}

class FeedbackLocalDataSourceImpl implements FeedbackLocalDataSource {
  FeedbackLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;
  static const String _outboxKey = 'sinkly.feedback_outbox';

  @override
  Future<void> saveFeedback(UserFeedbackModel feedback) async {
    // Small delay keeps the "sending" state visible — feels intentional.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _storage.setStringList(_outboxKey, [...pendingFeedbackPayloads(), jsonEncode(feedback.toJson())]);
  }

  @override
  List<String> pendingFeedbackPayloads() => _storage.getStringList(_outboxKey);
}

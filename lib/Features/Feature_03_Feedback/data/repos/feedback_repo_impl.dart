import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../data_sources/feedback_local_data_source.dart';
import '../data_sources/feedback_remote_data_source.dart';
import '../models/user_feedback_model.dart';
import 'feedback_repo.dart';

/// Saves every idea locally first (works offline), then delivers the outbox
/// to Supabase whenever it can.
class FeedbackRepoImpl implements FeedbackRepo {
  FeedbackRepoImpl({
    required FeedbackLocalDataSource localDataSource,
    required FeedbackRemoteDataSource remoteDataSource,
    required this._localeController,
  }) : _local = localDataSource,
       _remote = remoteDataSource;

  final FeedbackLocalDataSource _local;
  final FeedbackRemoteDataSource _remote;
  final LocaleController _localeController;

  static const int minimumMessageLength = 10;

  bool _flushing = false;

  @override
  Future<Either<Failure, Unit>> submitFeedback({required FeedbackCategory category, required String message}) async {
    final trimmed = message.trim();
    if (trimmed.length < minimumMessageLength) return left(const ValidationFailure('feedback_error_too_short'));
    final now = DateTime.now();
    // Same rule as the database trigger: 5 ideas per phone per rolling 24 h.
    if (_local.submissionsWithin(const Duration(days: 1), now: now) >= AppConstants.feedbackDailyLimit) {
      return left(const ValidationFailure('feedback_error_daily_limit'));
    }
    try {
      await _local.saveFeedback(
        UserFeedbackModel(
          id: 'fb_${now.microsecondsSinceEpoch}',
          category: category,
          message: trimmed,
          createdAt: now,
          languageCode: _localeController.locale.languageCode,
          appVersion: AppConstants.appVersion,
        ),
      );
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
    // Saved = success for the user. Deliver now if it's quick; a slow network
    // keeps going in the background (or on a later launch).
    await flushPending().timeout(const Duration(seconds: 3), onTimeout: () {});
    return right(unit);
  }

  @override
  Future<void> flushPending() async {
    if (_flushing) return;
    _flushing = true;
    try {
      for (final raw in _local.pendingFeedbackPayloads()) {
        final Map<String, dynamic> payload;
        try {
          payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {
          continue; // unreadable leftovers are skipped
        }
        final id = payload['id'] as String?;
        if (id == null) continue;
        try {
          await _remote.send(payload);
          await _local.removePending(id);
        } on FeedbackSendException catch (error) {
          if (error.error == FeedbackSendError.rejected) {
            await _local.removePending(id); // would never succeed: don't retry forever
            continue;
          }
          break; // offline: keep the rest for next time
        }
      }
    } catch (_) {
      // Best effort only: the outbox is kept for the next attempt.
    } finally {
      _flushing = false;
    }
  }
}

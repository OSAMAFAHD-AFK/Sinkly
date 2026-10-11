import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../data_sources/feedback_local_data_source.dart';
import '../models/user_feedback_model.dart';
import 'feedback_repo.dart';

class FeedbackRepoImpl implements FeedbackRepo {
  FeedbackRepoImpl({required FeedbackLocalDataSource localDataSource, required this._localeController})
    : _local = localDataSource;

  final FeedbackLocalDataSource _local;
  final LocaleController _localeController;

  static const int minimumMessageLength = 10;

  @override
  Future<Either<Failure, Unit>> submitFeedback({required FeedbackCategory category, required String message}) async {
    final trimmed = message.trim();
    if (trimmed.length < minimumMessageLength) return left(const ValidationFailure('feedback_error_too_short'));
    try {
      final now = DateTime.now();
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
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

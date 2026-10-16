import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_feedback_model.dart';

abstract class FeedbackRepo {
  Future<Either<Failure, Unit>> submitFeedback({required FeedbackCategory category, required String message});

  /// Sends ideas written while offline. Safe to call any time; never throws.
  Future<void> flushPending();
}

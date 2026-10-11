import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_feedback_model.dart';
import '../../data/repos/feedback_repo.dart';

part 'feedback_state.dart';

/// Drives the "Help Build Sinkly" screen: category, message, submission.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this._repo) : super(const FeedbackState());

  final FeedbackRepo _repo;

  void selectCategory(FeedbackCategory category) =>
      emit(state.copyWith(category: category, status: FeedbackSubmissionStatus.editing));

  void updateMessage(String message) =>
      emit(state.copyWith(message: message, status: FeedbackSubmissionStatus.editing));

  Future<void> submitFeedback() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: FeedbackSubmissionStatus.submitting));
    final result = await _repo.submitFeedback(category: state.category, message: state.message);
    result.fold(
      (failure) => emit(state.copyWith(status: FeedbackSubmissionStatus.failure, failureKey: failure.messageKey)),
      (_) => emit(state.copyWith(status: FeedbackSubmissionStatus.success)),
    );
  }

  /// Clears the form after the success dialog so another idea can be sent.
  void resetForm() => emit(FeedbackState(category: state.category));
}

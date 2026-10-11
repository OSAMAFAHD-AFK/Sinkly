part of 'feedback_cubit.dart';

enum FeedbackSubmissionStatus { editing, submitting, success, failure }

class FeedbackState extends Equatable {
  const FeedbackState({
    this.category = FeedbackCategory.newFeature,
    this.message = '',
    this.status = FeedbackSubmissionStatus.editing,
    this.failureKey,
  });

  final FeedbackCategory category;
  final String message;
  final FeedbackSubmissionStatus status;
  final String? failureKey;

  bool get canSubmit => message.trim().isNotEmpty && status != FeedbackSubmissionStatus.submitting;

  FeedbackState copyWith({
    FeedbackCategory? category,
    String? message,
    FeedbackSubmissionStatus? status,
    String? failureKey,
  }) => FeedbackState(
    category: category ?? this.category,
    message: message ?? this.message,
    status: status ?? this.status,
    failureKey: failureKey,
  );

  @override
  List<Object?> get props => [category, message, status, failureKey];
}

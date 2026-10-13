import 'package:equatable/equatable.dart';

/// Suggestion categories (single-select chips). The [id] is the stable value
/// stored in the backend so the roadmap can be sorted by category.
enum FeedbackCategory {
  newFeature(
    id: 'new_feature',
    emoji: '💡',
    translationKey: 'feedback_category_new_feature',
    hintKey: 'feedback_input_placeholder',
  ),
  uiEnhancement(
    id: 'ui_enhancement',
    emoji: '🎨',
    translationKey: 'feedback_category_ui_enhancement',
    hintKey: 'feedback_hint_ui_enhancement',
  ),
  bugReport(
    id: 'bug_report',
    emoji: '🐛',
    translationKey: 'feedback_category_bug_report',
    hintKey: 'feedback_hint_bug_report',
  ),
  appLockOptions(
    id: 'app_lock_options',
    emoji: '⚙️',
    translationKey: 'feedback_category_app_lock_options',
    hintKey: 'feedback_hint_app_lock_options',
  );

  const FeedbackCategory({required this.id, required this.emoji, required this.translationKey, required this.hintKey});

  final String id;
  final String emoji;
  final String translationKey;

  /// Placeholder of the message field while this category is selected.
  final String hintKey;
}

/// One user suggestion sent to the product team.
class UserFeedbackModel extends Equatable {
  const UserFeedbackModel({
    required this.id,
    required this.category,
    required this.message,
    required this.createdAt,
    required this.languageCode,
    required this.appVersion,
  });

  final String id;
  final FeedbackCategory category;
  final String message;
  final DateTime createdAt;
  final String languageCode;
  final String appVersion;

  /// Shape of the Firestore document / REST payload.
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.id,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'languageCode': languageCode,
    'appVersion': appVersion,
  };

  @override
  List<Object?> get props => [id, category, message, createdAt, languageCode, appVersion];
}

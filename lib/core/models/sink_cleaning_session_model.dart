import 'package:equatable/equatable.dart';

import 'weekly_lock_schedule_model.dart';

/// One completed "clean the sink → snap a photo → unlock" cycle.
class SinkCleaningSessionModel extends Equatable {
  const SinkCleaningSessionModel({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    this.triggeringMeal,
    this.photoPath,
  });

  final String id;
  final DateTime startedAt;
  final DateTime completedAt;

  /// Meal that caused the lock (null when the lock was triggered manually).
  final MealType? triggeringMeal;

  /// Local path of the verification photo (kept on-device for privacy).
  final String? photoPath;

  Duration get cleaningDuration => completedAt.difference(startedAt);

  factory SinkCleaningSessionModel.fromJson(Map<String, dynamic> json) => SinkCleaningSessionModel(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: DateTime.parse(json['completedAt'] as String),
    triggeringMeal: json['triggeringMeal'] == null ? null : MealType.fromName(json['triggeringMeal'] as String),
    photoPath: json['photoPath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'triggeringMeal': triggeringMeal?.name,
    'photoPath': photoPath,
  };

  @override
  List<Object?> get props => [id, startedAt, completedAt, triggeringMeal, photoPath];
}

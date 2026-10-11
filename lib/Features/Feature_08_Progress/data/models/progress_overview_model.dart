import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';
import 'achievement_badge_model.dart';

/// Everything the Progress tab displays.
class ProgressOverviewModel extends Equatable {
  const ProgressOverviewModel({required this.stats, required this.achievements, required this.recentSessions});

  final SinkProgressStatsModel stats;
  final List<AchievementBadgeModel> achievements;

  /// Newest first, capped for performance.
  final List<SinkCleaningSessionModel> recentSessions;

  @override
  List<Object?> get props => [stats, achievements, recentSessions];
}

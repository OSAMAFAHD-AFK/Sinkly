import 'package:equatable/equatable.dart';

import '../../../../core/models/sink_progress_stats_model.dart';

/// Gamified milestone (unlocked from progress stats).
class AchievementBadgeModel extends Equatable {
  const AchievementBadgeModel({required this.id, required this.emoji, required this.titleKey, required this.progress});

  final String id;
  final String emoji;
  final String titleKey;

  /// 0 … 1 (1 = unlocked).
  final double progress;

  bool get isUnlocked => progress >= 1;

  static List<AchievementBadgeModel> fromStats(SinkProgressStatsModel stats) {
    double ratio(num value, num goal) => (value / goal).clamp(0, 1).toDouble();
    return [
      AchievementBadgeModel(
        id: 'first_clean',
        // ✨ not 🫧: the bubbles emoji (Unicode 14) shows as an empty box on
        // many Android phones.
        emoji: '✨',
        titleKey: 'badge_first_clean',
        progress: ratio(stats.totalCleans, 1),
      ),
      AchievementBadgeModel(
        id: 'streak_3',
        emoji: '🔥',
        titleKey: 'badge_streak_3',
        progress: ratio(stats.bestStreakDays, 3),
      ),
      AchievementBadgeModel(
        id: 'streak_7',
        emoji: '🏆',
        titleKey: 'badge_streak_7',
        progress: ratio(stats.bestStreakDays, 7),
      ),
      AchievementBadgeModel(
        id: 'cleans_10',
        emoji: '🧽',
        titleKey: 'badge_cleans_10',
        progress: ratio(stats.totalCleans, 10),
      ),
      AchievementBadgeModel(
        id: 'cleans_50',
        emoji: '💎',
        titleKey: 'badge_cleans_50',
        progress: ratio(stats.totalCleans, 50),
      ),
      AchievementBadgeModel(
        id: 'hours_10',
        emoji: '⏳',
        titleKey: 'badge_hours_10',
        progress: ratio(stats.minutesReclaimed, 600),
      ),
    ];
  }

  @override
  List<Object?> get props => [id, emoji, titleKey, progress];
}

import 'package:flutter/material.dart';

import '../../../../../core/models/sink_progress_stats_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Three glass stat tiles: streak · cleans this week · time reclaimed.
class HomeQuickStatsRowWidget extends StatelessWidget {
  const HomeQuickStatsRowWidget({super.key, required this.stats});

  final SinkProgressStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final hours = stats.minutesReclaimed ~/ 60;
    final minutes = stats.minutesReclaimed % 60;
    return Row(
      children: [
        Expanded(
          child: _StatTile(emoji: '🔥', value: '${stats.currentStreakDays}', label: context.tr('stat_day_streak')),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(emoji: '🧽', value: '${stats.cleansThisWeek}', label: context.tr('stat_cleans_week')),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            emoji: '⏳',
            value: hours > 0 ? '${hours}h${minutes > 0 ? ' ${minutes}m' : ''}' : '${minutes}m',
            label: context.tr('stat_time_reclaimed'),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      borderRadius: AppRadii.mediumAll,
      shadows: AppShadows.soft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.title),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 2, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

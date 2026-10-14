import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../data/models/lock_overlay_snapshot_model.dart';

/// What's on the other side of a few minutes: the time it takes, the streak
/// to protect and the Mom Points to earn. Framed as gains, never as guilt.
class LockOverlayRewardStripWidget extends StatelessWidget {
  const LockOverlayRewardStripWidget({super.key, required this.snapshot});

  final LockOverlaySnapshotModel snapshot;

  @override
  Widget build(BuildContext context) {
    final streak = snapshot.currentStreakDays;
    final tiles = [
      _RewardTile(
        emoji: '⏱️',
        value: context.minutes(snapshot.sprintMinutes),
        label: context.tr('lock_overlay_stat_time_label'),
      ),
      _RewardTile(
        emoji: '🔥',
        value: streak > 0 ? '$streak' : context.tr('lock_overlay_stat_streak_new_value'),
        label: context.tr(streak > 0 ? 'lock_overlay_stat_streak_label' : 'lock_overlay_stat_streak_new_label'),
      ),
      _RewardTile(
        emoji: '💖',
        value: '+${AppConstants.momPointsPerClean}',
        label: context.tr('lock_overlay_stat_points_label'),
        highlight: true,
        forceLtrValue: true,
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, tile) in tiles.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: tile
                  .animate(delay: (450 + index * 110).ms)
                  .fadeIn(duration: 350.ms)
                  .scaleXY(begin: 0.85, curve: Curves.easeOutBack, duration: 500.ms),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.emoji,
    required this.value,
    required this.label,
    this.highlight = false,
    this.forceLtrValue = false,
  });

  final String emoji;
  final String value;
  final String label;
  final bool highlight;

  /// Keeps "+10" from turning into "10+" inside Arabic layouts.
  final bool forceLtrValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? null : AppColors.glassFillStrong,
        gradient: highlight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE3EC), Color(0xFFFFF4E0)],
              )
            : null,
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            textDirection: forceLtrValue ? TextDirection.ltr : null,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 11.5, height: 1.25),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/app_icons_wrap_widget.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';

/// Stage 4 — the reward: confetti, unlocked apps "popping" free and the
/// session stats. Ends the loop on a dopamine high (earned, not stolen).
class UnlockRewardCelebrationWidget extends StatelessWidget {
  const UnlockRewardCelebrationWidget({
    super.key,
    required this.session,
    required this.stats,
    required this.unlockedApps,
    required this.onDone,
  });

  final SinkCleaningSessionModel session;
  final SinkProgressStatsModel stats;
  final List<BlockableAppModel> unlockedApps;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final duration = session.cleaningDuration;
    final durationLabel = AppFunctions.formatCountdown(duration.inSeconds.clamp(0, 99 * 60));

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const Center(
                    child: GlassIconOrbWidget(
                      icon: Icons.lock_open_rounded,
                      size: 110,
                      glowColor: AppColors.success,
                      iconColor: AppColors.success,
                    ),
                  ).animate().scaleXY(begin: 0.4, end: 1, duration: 700.ms, curve: Curves.elasticOut),
                  Text(
                    context.tr('reward_title'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.display,
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('reward_subtitle'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ).animate(delay: 300.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.lg),
                  AppIconsWrapWidget(
                    apps: unlockedApps,
                    size: 50,
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    iconBuilder: (index, icon) => icon
                        .animate(delay: (400 + index * 90).ms)
                        .scaleXY(begin: 0, end: 1, duration: 500.ms, curve: Curves.elasticOut),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _RewardStat(emoji: '⏱️', value: durationLabel, label: context.tr('reward_stat_time')),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RewardStat(
                          emoji: '⏳',
                          value: '+${AppConstants.minutesReclaimedPerClean}m',
                          label: context.tr('reward_stat_reclaimed'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RewardStat(
                          emoji: '🔥',
                          value: '${stats.currentStreakDays}',
                          label: context.tr('stat_day_streak'),
                        ),
                      ),
                    ],
                  ).animate(delay: 650.ms).fadeIn().slideY(begin: 0.15),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.xs,
                AppSpacing.screenGutter,
                AppSpacing.md,
              ),
              child: CustomPrimaryButton(
                label: context.tr('reward_cta'),
                icon: Icons.celebration_rounded,
                onPressed: onDone,
              ),
            ),
          ],
        ),
        const Positioned.fill(child: ConfettiBurstWidget(particleCount: 80)),
      ],
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      borderRadius: AppRadii.mediumAll,
      shadows: AppShadows.soft,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.title),
          ),
          Text(label, maxLines: 2, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

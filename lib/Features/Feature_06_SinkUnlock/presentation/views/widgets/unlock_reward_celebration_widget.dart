import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import 'unlock_celebration_heroine_stage_widget.dart';

/// Stage 4 — the reward. The heroine celebrates WITH the user (the padlock
/// bursts open beside her), the apps pop back free and one calm summary card
/// lands. Ends the loop on a warm high: earned, not stolen.
class UnlockRewardCelebrationWidget extends StatefulWidget {
  const UnlockRewardCelebrationWidget({
    super.key,
    required this.session,
    required this.stats,
    required this.unlockedApps,
    required this.onDone,
    this.userName = '',
  });

  final SinkCleaningSessionModel session;
  final SinkProgressStatsModel stats;
  final List<BlockableAppModel> unlockedApps;
  final VoidCallback onDone;
  final String userName;

  @override
  State<UnlockRewardCelebrationWidget> createState() => _UnlockRewardCelebrationWidgetState();
}

class _UnlockRewardCelebrationWidgetState extends State<UnlockRewardCelebrationWidget> {
  /// Bumped to replay the confetti when she is tapped.
  int _confettiRound = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // The stage gets what the content leaves; on short phones or huge
            // text it keeps a minimum and the page scrolls instead.
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stageHeight = (box.maxHeight - (250 + 170 * textScale)).clamp(200.0, 340.0);
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    0,
                    AppSpacing.screenGutter,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: stageHeight,
                        child: UnlockCelebrationHeroineStageWidget(
                          userName: widget.userName,
                          onCelebrate: () => setState(() => _confettiRound++),
                        ),
                      ).animate().fadeIn(duration: 450.ms).scaleXY(begin: 0.9, curve: Curves.easeOutBack, duration: 700.ms),
                      Column(
                        children: [
                          Text(context.tr('reward_title'), textAlign: TextAlign.center, style: AppTextStyles.display)
                              .animate(delay: 250.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.3, curve: Curves.easeOutBack),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('reward_subtitle'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body,
                          ).animate(delay: 350.ms).fadeIn(),
                          if (widget.unlockedApps.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _FreedAppsRow(apps: widget.unlockedApps),
                          ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: _SessionSummaryCard(session: widget.session, stats: widget.stats)
                            .animate(delay: 600.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                      ),
                      CustomPrimaryButton(
                        label: context.tr('reward_cta'),
                        icon: Icons.celebration_rounded,
                        showShimmer: true,
                        onPressed: widget.onDone,
                      ).animate(delay: 900.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: IgnorePointer(child: ConfettiBurstWidget(key: ValueKey(_confettiRound), particleCount: 80)),
        ),
      ],
    );
  }
}

/// The freed apps pop out one by one (each with a green "open" badge), then
/// float gently, as if they were breathing again.
class _FreedAppsRow extends StatelessWidget {
  const _FreedAppsRow({required this.apps});

  final List<BlockableAppModel> apps;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        for (final (index, app) in apps.indexed)
          SizedBox.square(
                dimension: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BlockableAppIconWidget(app: app, size: 46),
                    PositionedDirectional(
                      end: -5,
                      bottom: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.lock_open_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              // Endless gentle float (each icon at its own pace)…
              .animate(onPlay: (c) => c.repeat(reverse: true), delay: (1100 + index * 90).ms)
              .moveY(begin: 0, end: -4, duration: (1300 + index * 120).ms, curve: Curves.easeInOut)
              // …after an elastic pop-in, one by one.
              .animate(delay: (450 + index * 90).ms)
              .scaleXY(begin: 0, end: 1, duration: 600.ms, curve: Curves.elasticOut),
      ],
    );
  }
}

/// One glass card with the three results side by side, split by hairlines:
/// how fast it went, the time won back and the streak.
class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session, required this.stats});

  final SinkCleaningSessionModel session;
  final SinkProgressStatsModel stats;

  /// Below this the user skipped the sprint ("already clean → photo").
  static const Duration _expressThreshold = Duration(seconds: 45);

  @override
  Widget build(BuildContext context) {
    final duration = session.cleaningDuration;
    final express = duration < _expressThreshold;
    final items = [
      express
          ? _Stat(
              emoji: '⚡',
              value: context.tr('reward_stat_express_value'),
              label: context.tr('reward_stat_express'),
            )
          : _Stat(
              emoji: '⏱️',
              value: AppFunctions.formatCountdown(duration.inSeconds.clamp(0, 99 * 60)),
              label: context.tr('reward_stat_time'),
              ltrValue: true,
            ),
      _Stat(
        emoji: '⏳',
        value: '+${AppConstants.minutesReclaimedPerClean}',
        label: context.tr('reward_stat_reclaimed_minutes'),
        ltrValue: true,
      ),
      _Stat(emoji: '🔥', value: '${stats.currentStreakDays}', label: context.tr('stat_day_streak'), ltrValue: true),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: AppRadii.cardAll,
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: AppShadows.soft,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, stat) in items.indexed) ...[
              if (index > 0)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: AppColors.divider,
                ),
              Expanded(
                child: stat
                    .animate(delay: (750 + index * 110).ms)
                    .fadeIn(duration: 350.ms)
                    .scaleXY(begin: 0.85, curve: Curves.easeOutBack, duration: 500.ms),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.value, required this.label, this.ltrValue = false});

  final String emoji;
  final String value;
  final String label;

  /// Numbers like "+30" / "03:12" keep their order inside Arabic layouts.
  final bool ltrValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textDirection: ltrValue ? TextDirection.ltr : null,
              style: AppTextStyles.titleSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
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

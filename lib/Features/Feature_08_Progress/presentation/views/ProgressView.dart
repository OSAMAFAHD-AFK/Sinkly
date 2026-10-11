import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/custom_card_container.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../manager/progress_cubit.dart';
import 'widgets/achievement_badge_tile_widget.dart';
import 'widgets/recent_session_tile_widget.dart';
import 'widgets/streak_hero_card_widget.dart';
import 'widgets/weekly_cleans_bar_chart_widget.dart';

/// Progress tab: streak, weekly chart, totals, badges and history.
class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProgressCubit>().state;
    final overview = state.overview;
    final stats = overview.stats;
    final reclaimedHours = (stats.minutesReclaimed / 60).toStringAsFixed(stats.minutesReclaimed % 60 == 0 ? 0 : 1);

    return GlassScreenScaffold(
      palette: MeshPalette.warm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 0),
            sliver: SliverList.list(
              children: [
                Text(context.tr('progress_screen_title'), style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text(context.tr('progress_screen_subtitle'), style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
                StreakHeroCardWidget(currentStreak: stats.currentStreakDays, bestStreak: stats.bestStreakDays),
                const SizedBox(height: AppSpacing.md),
                WeeklyCleansBarChartWidget(cleansPerDay: stats.cleansPerDayLast7, today: state.today),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _TotalTile(
                        emoji: '🧽',
                        value: '${stats.totalCleans}',
                        label: context.tr('progress_total_cleans'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TotalTile(
                        emoji: '⏳',
                        value: context.tr('hours_value', {'h': reclaimedHours}),
                        label: context.tr('stat_time_reclaimed'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TotalTile(
                        emoji: '⚡',
                        value: AppFunctions.formatCountdown(stats.averageCleaningDuration.inSeconds.clamp(0, 99 * 60)),
                        label: context.tr('progress_avg_sprint'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeaderWidget(title: context.tr('progress_badges_section')),
              ].animate(interval: 40.ms).fadeIn(duration: 350.ms).slideY(begin: 0.05),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 128,
              ),
              itemCount: overview.achievements.length,
              itemBuilder: (context, index) =>
                  AchievementBadgeTileWidget(badge: overview.achievements[index])
                      .animate(delay: (200 + index * 50).ms)
                      .fadeIn()
                      .scaleXY(begin: 0.9, curve: Curves.easeOutBack),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.lg, AppSpacing.screenGutter, 130),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeaderWidget(title: context.tr('progress_history_section')),
                  CustomCardContainer(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: overview.recentSessions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Column(
                              children: [
                                const Text('🫧', style: TextStyle(fontSize: 34)),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  context.tr('progress_history_empty'),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (final (index, session) in overview.recentSessions.indexed) ...[
                                if (index > 0) const Divider(height: 1),
                                RecentSessionTileWidget(session: session, today: state.today),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.emoji, required this.value, required this.label});

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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import '../manager/home_cubit.dart';
import 'widgets/home_action_banner_widget.dart';
import 'widgets/home_header_widget.dart';
import 'widgets/home_quick_stats_row_widget.dart';
import 'widgets/lock_status_hero_card_widget.dart';
import 'widgets/today_meal_timeline_widget.dart';

/// Home tab: lock status hero, today's meals, quick stats and banners.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeCubit>().state;
    final dashboard = state.dashboard;
    final isPremium = context.select((SubscriptionCubit c) => c.state.isPremium);

    final sections = <Widget>[
      HomeHeaderWidget(userName: dashboard.plan.displayName, now: state.now),
      const SizedBox(height: AppSpacing.lg),
      LockStatusHeroCardWidget(
        lockStatus: dashboard.lockStatus,
        blockedApps: dashboard.plan.blockedApps,
        now: state.now,
        sprintMinutes: dashboard.plan.sprintMinutes,
        onStartSinkSprint: () => context.push(AppRouter.kSinkUnlockView),
      ),
      // Only if an access granted during onboarding was later switched off.
      if (state.protection.isProtectionBroken) ...[
        const SizedBox(height: AppSpacing.sm),
        HomeActionBannerWidget(
          emoji: '⚠️',
          title: context.tr('protection_off_title'),
          subtitle: context.tr('protection_off_subtitle'),
          highlighted: true,
          onTap: context.read<HomeCubit>().fixProtection,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      SectionHeaderWidget(
        title: context.tr('home_today_section'),
        trailing: GestureDetector(
          onTap: () => context.go(AppRouter.kLockScheduleView),
          child: Text(
            context.tr('edit'),
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryInk, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      TodayMealTimelineWidget(
        meals: dashboard.todayMeals,
        onEditSchedule: () => context.go(AppRouter.kLockScheduleView),
      ),
      const SizedBox(height: AppSpacing.lg),
      SectionHeaderWidget(title: context.tr('home_stats_section')),
      HomeQuickStatsRowWidget(stats: dashboard.stats),
      const SizedBox(height: AppSpacing.lg),
      if (!isPremium) ...[
        HomeActionBannerWidget(
          emoji: '💎',
          title: context.tr('home_premium_title'),
          subtitle: context.tr('home_premium_subtitle'),
          highlighted: true,
          onTap: () => context.push(AppRouter.kPaywallView),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      HomeActionBannerWidget(
        emoji: '🚀',
        title: context.tr('home_feedback_title'),
        subtitle: context.tr('home_feedback_subtitle'),
        onTap: () => context.push(AppRouter.kFeedbackView),
      ),
    ];

    return GlassScreenScaffold(
      safeAreaBottom: false,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          AppSpacing.mainTabScrollBottom(context),
        ),
        children: sections
            .animate(interval: 45.ms)
            .fadeIn(duration: 380.ms)
            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
      ),
    );
  }
}

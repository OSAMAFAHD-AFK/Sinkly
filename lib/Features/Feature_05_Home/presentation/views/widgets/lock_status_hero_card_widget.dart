import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';

/// The hero of the Home tab: either "Apps locked → clean the sink" or
/// "All clear → next lock at …". Cross-fades between both states.
class LockStatusHeroCardWidget extends StatelessWidget {
  const LockStatusHeroCardWidget({
    super.key,
    required this.lockStatus,
    required this.blockedApps,
    required this.now,
    required this.sprintMinutes,
    required this.onStartSinkSprint,
  });

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final DateTime now;
  final int sprintMinutes;
  final VoidCallback onStartSinkSprint;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.slow,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
      ),
      child: lockStatus.isLocked
          ? _LockedContent(
              key: const ValueKey('locked'),
              lockStatus: lockStatus,
              blockedApps: blockedApps,
              sprintMinutes: sprintMinutes,
              onStart: onStartSinkSprint,
            )
          : _UnlockedContent(
              key: const ValueKey('unlocked'),
              lockStatus: lockStatus,
              blockedApps: blockedApps,
              now: now,
            ),
    );
  }
}

class _LockedContent extends StatelessWidget {
  const _LockedContent({
    super.key,
    required this.lockStatus,
    required this.blockedApps,
    required this.sprintMinutes,
    required this.onStart,
  });

  final int sprintMinutes;
  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final mealName = lockStatus.lockingMeal == null
        ? context.tr('home_locked_manual')
        : context.tr(lockStatus.lockingMeal!.translationKey);
    return CustomCardContainer(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF2FFFFFF), Color(0xE6FFF1E6)],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.ink,
                      borderRadius: AppRadii.mediumAll,
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.06, duration: 900.ms, curve: Curves.easeInOut),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(
                      label: context.tr('home_status_locked'),
                      color: AppColors.danger,
                      background: AppColors.dangerSoft,
                    ),
                    const SizedBox(height: 4),
                    if (lockStatus.lockedSince != null)
                      Text(
                        context.tr('home_locked_since', {
                          'time': AppFunctions.formatDateTimeClock(context, lockStatus.lockedSince!),
                        }),
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.tr('home_locked_title', {'meal': mealName}), style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(context.tr('home_locked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final app in blockedApps) BlockableAppIconWidget(app: app, size: 38, showLockBadge: true)],
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomPrimaryButton(
            label: context.tr('home_start_sprint_cta', {'duration': context.minutes(sprintMinutes)}),
            icon: Icons.cleaning_services_rounded,
            showShimmer: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _UnlockedContent extends StatelessWidget {
  const _UnlockedContent({super.key, required this.lockStatus, required this.blockedApps, required this.now});

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final nextAt = lockStatus.nextLockAt;
    return CustomCardContainer(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF2FFFFFF), Color(0xE6E3F8EF)],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: AppGradients.success,
                  borderRadius: AppRadii.mediumAll,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatusPill(
                  label: context.tr('home_status_unlocked'),
                  color: AppColors.success,
                  background: AppColors.successSoft,
                ),
              ),
              const Text(
                '✨',
                style: TextStyle(fontSize: 26),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.05, end: 0.05, duration: 1200.ms),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.tr('home_unlocked_title'), style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(context.tr('home_unlocked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: AppRadii.mediumAll,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primaryInk),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: nextAt == null
                      ? Text(
                          context.tr('home_no_upcoming_lock'),
                          style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('home_next_lock', {
                                'meal': context.tr(lockStatus.nextLockMeal?.translationKey ?? 'meal_dinner'),
                                'time': AppFunctions.formatDateTimeClock(context, nextAt),
                              }),
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                            ),
                            Text(
                              context.tr('home_next_lock_in', {
                                'duration': AppFunctions.formatCompactDuration(context, nextAt.difference(now)),
                              }),
                              style: AppTextStyles.caption.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                ),
                SizedBox(
                  width: 26.0 + (blockedApps.take(3).length - 1).clamp(0, 2) * 14,
                  height: 26,
                  child: Stack(
                    children: [
                      for (final (index, app) in blockedApps.take(3).indexed)
                        PositionedDirectional(
                          start: index * 14.0,
                          child: BlockableAppIconWidget(app: app, size: 26),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: AppRadii.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

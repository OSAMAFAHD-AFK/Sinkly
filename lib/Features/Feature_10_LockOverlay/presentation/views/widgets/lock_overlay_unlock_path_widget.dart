import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../data/models/lock_overlay_snapshot_model.dart';

/// The way through, at a glance: a quick clean-up → one photo → apps back.
/// Below it, the streak to protect (or a fresh one to start). Framed as a
/// short, doable path, never as a wall.
class LockOverlayUnlockPathWidget extends StatelessWidget {
  const LockOverlayUnlockPathWidget({super.key, required this.snapshot});

  final LockOverlaySnapshotModel snapshot;

  @override
  Widget build(BuildContext context) {
    final streak = snapshot.currentStreakDays;
    final steps = [
      _PathStep(
        emoji: '🧽',
        label: context.tr('lock_overlay_path_clean', {'duration': context.minutes(snapshot.sprintMinutes)}),
      ),
      _PathStep(emoji: '📸', label: context.tr('lock_overlay_path_photo')),
      _PathStep(emoji: '🔓', label: context.tr('lock_overlay_path_free'), isGoal: true),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.glassFillStrong,
            borderRadius: AppRadii.cardAll,
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, step) in steps.indexed) ...[
                if (index > 0) _PathConnector(delay: (550 + index * 160).ms),
                Expanded(
                  child: step
                      .animate(delay: (450 + index * 160).ms)
                      .fadeIn(duration: 350.ms)
                      .scaleXY(begin: 0.8, curve: Curves.easeOutBack, duration: 500.ms),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StreakPill(
          text: streak > 0
              ? context.tr('lock_overlay_streak_keep', {'count': '$streak'})
              : context.tr('lock_overlay_streak_start'),
        ).animate(delay: 950.ms).fadeIn(duration: 400.ms),
      ],
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({required this.emoji, required this.label, this.isGoal = false});

  final String emoji;
  final String label;

  /// The last step (apps back) glows green and breathes.
  final bool isGoal;

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isGoal ? AppColors.successSoft : AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppShadows.soft,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
    if (isGoal) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true), delay: 1200.ms)
          .scaleXY(begin: 1, end: 1.08, duration: 900.ms, curve: Curves.easeInOut);
    }
    return Column(
      children: [
        badge,
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: isGoal ? AppColors.success : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Three dots that light up in turn, leading the eye to the next step.
/// Direction-agnostic, so it reads right in both LTR and RTL.
class _PathConnector extends StatelessWidget {
  const _PathConnector({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Vertically centered on the 48px badges.
      padding: const EdgeInsets.only(top: 21),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                )
                .animate(onPlay: (c) => c.repeat(), delay: delay + (i * 140).ms)
                .fade(begin: 0.25, end: 1, duration: 420.ms)
                .then()
                .fade(begin: 1, end: 0.25, duration: 420.ms),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
    );
  }
}

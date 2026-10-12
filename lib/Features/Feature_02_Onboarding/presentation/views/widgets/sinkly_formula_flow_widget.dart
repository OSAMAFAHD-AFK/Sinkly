import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Screen 11 visual — the Sinkly loop as a vertical, step-by-step timeline:
/// meal ends → apps lock → timed sink sprint → photo → guilt-free reward.
class SinklyFormulaFlowWidget extends StatefulWidget {
  const SinklyFormulaFlowWidget({super.key, required this.blockedApps});

  final List<BlockableAppModel> blockedApps;

  @override
  State<SinklyFormulaFlowWidget> createState() => _SinklyFormulaFlowWidgetState();
}

class _SinklyFormulaFlowWidgetState extends State<SinklyFormulaFlowWidget> with SingleTickerProviderStateMixin {
  static const int _stepCount = 5;

  // A light "current" travels down the timeline again and again, so the
  // user literally watches the loop play out: meal → lock → sprint → photo → reward.
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 7))
    ..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <({String emoji, String title, String subtitle, Widget? trailing})>[
      (
        emoji: '🍝',
        title: context.tr('formula_step_meal_title'),
        subtitle: context.tr('formula_step_meal_subtitle'),
        trailing: null,
      ),
      (
        emoji: '🔒',
        title: context.tr('formula_step_lock_title'),
        subtitle: context.tr('formula_step_lock_subtitle'),
        trailing: _AppStack(apps: widget.blockedApps),
      ),
      (
        emoji: '🧽',
        title: context.tr('formula_step_sprint_title', {
          'duration': context.minutes(AppConstants.sinkSprintDuration.inMinutes),
        }),
        subtitle: context.tr('formula_step_sprint_subtitle'),
        trailing: null,
      ),
      (
        emoji: '📸',
        title: context.tr('formula_step_photo_title'),
        subtitle: context.tr('formula_step_photo_subtitle'),
        trailing: null,
      ),
      (
        emoji: '🎉',
        title: context.tr('formula_step_reward_title'),
        subtitle: context.tr('formula_step_reward_subtitle'),
        trailing: null,
      ),
    ];

    return CustomCardContainer(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final activeIndex = (_loop.value * _stepCount).floor().clamp(0, _stepCount - 1);
          return Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                _FormulaStepRow(
                      emoji: steps[i].emoji,
                      title: steps[i].title,
                      subtitle: steps[i].subtitle,
                      trailing: steps[i].trailing,
                      isLast: i == steps.length - 1,
                      isReward: i == steps.length - 1,
                      isActive: i == activeIndex,
                    )
                    .animate(delay: (250 + i * 220).ms)
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: context.flipX(0.1), curve: Curves.easeOutCubic),
            ],
          );
        },
      ),
    );
  }
}

class _FormulaStepRow extends StatelessWidget {
  const _FormulaStepRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isLast,
    required this.isReward,
    this.isActive = false,
    this.trailing,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool isReward;
  final bool isActive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AnimatedScale(
                scale: isActive ? 1.16 : 1,
                duration: AppDurations.medium,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: AppDurations.medium,
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isReward || isActive ? AppGradients.primaryButton : null,
                    color: isReward || isActive ? null : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isReward || isActive
                        ? AppShadows.primaryGlow(strength: isActive ? 0.9 : 0.6)
                        : AppShadows.soft,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 21)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.15)],
                      ),
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyStrong.copyWith(color: isReward ? AppColors.primaryInk : AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(top: 6), child: trailing),
        ],
      ),
    );
  }
}

/// Overlapping mini app icons ("TikTok, Instagram, +2").
class _AppStack extends StatelessWidget {
  const _AppStack({required this.apps});

  final List<BlockableAppModel> apps;

  @override
  Widget build(BuildContext context) {
    final visible = apps.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 26.0 + (visible.length - 1) * 16,
      height: 26,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            PositionedDirectional(
              start: i * 16.0,
              child: BlockableAppIconWidget(app: visible[i], size: 26),
            ),
        ],
      ),
    );
  }
}

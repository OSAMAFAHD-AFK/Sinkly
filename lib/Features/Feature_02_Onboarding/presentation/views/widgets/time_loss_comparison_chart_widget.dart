import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Screen 7 visual: "5 minutes of washing" vs "1.5 hours of avoiding",
/// followed by the weekly & yearly cost of procrastination.
class TimeLossComparisonChartWidget extends StatelessWidget {
  const TimeLossComparisonChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const weeklyHours = AppConstants.averageHoursLostPerDay * 7;
    final yearlyDays = (AppConstants.averageHoursLostPerDay * 365 / 24).round();
    final washMinutes = AppConstants.sinkSprintDuration.inMinutes;
    final ratio = washMinutes / (AppConstants.averageHoursLostPerDay * 60);

    return Column(
      children: [
        CustomCardContainer(
          padding: const EdgeInsets.all(AppSpacing.lg - 2),
          child: Column(
            children: [
              _ComparisonBar(
                emoji: '🧽',
                label: context.tr('time_loss_washing_label'),
                valueLabel: context.tr('duration_minutes', {'m': '$washMinutes'}),
                fraction: ratio.clamp(0.06, 1.0),
                gradient: AppGradients.success,
                delayMs: 200,
              ),
              const SizedBox(height: AppSpacing.md),
              _ComparisonBar(
                emoji: '📱',
                label: context.tr('time_loss_avoiding_label'),
                valueLabel: context.tr('time_loss_avoiding_value'),
                fraction: 1,
                gradient: const LinearGradient(colors: [Color(0xFFFFB199), AppColors.danger]),
                delayMs: 450,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _LossStatTile(
                value: context.tr('hours_value', {'h': weeklyHours.toStringAsFixed(1)}),
                caption: context.tr('time_loss_per_week'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LossStatTile(
                value: context.tr('days_value', {'d': '$yearlyDays'}),
                caption: context.tr('time_loss_per_year'),
              ),
            ),
          ],
        ).animate(delay: 900.ms).fadeIn().slideY(begin: 0.2),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.emoji,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.gradient,
    required this.delayMs,
  });

  final String emoji;
  final String label;
  final String valueLabel;
  final double fraction;
  final Gradient gradient;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14))),
            Text(valueLabel, style: AppTextStyles.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          decoration: BoxDecoration(color: AppColors.divider.withValues(alpha: 0.7), borderRadius: AppRadii.pillAll),
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: AlignmentDirectional.centerStart,
              child:
                  Container(
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(gradient: gradient, borderRadius: AppRadii.pillAll),
                      )
                      .animate(delay: delayMs.ms)
                      .scaleX(
                        begin: 0,
                        end: 1,
                        alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
                        duration: 900.ms,
                        curve: Curves.easeOutCubic,
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LossStatTile extends StatelessWidget {
  const _LossStatTile({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      shadows: AppShadows.soft,
      borderRadius: AppRadii.mediumAll,
      child: Column(
        children: [
          Text(value, style: AppTextStyles.title.copyWith(color: AppColors.danger)),
          const SizedBox(height: 2),
          Text(caption, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

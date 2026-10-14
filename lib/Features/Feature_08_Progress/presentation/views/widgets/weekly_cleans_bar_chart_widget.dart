import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Last-7-days bar chart of cleans. Bars grow in with a staggered tween;
/// today's bar uses the brand gradient.
class WeeklyCleansBarChartWidget extends StatelessWidget {
  const WeeklyCleansBarChartWidget({super.key, required this.cleansPerDay, required this.today});

  /// Oldest → today (7 values).
  final List<int> cleansPerDay;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final maxValue = cleansPerDay.fold<int>(1, (max, value) => value > max ? value : max);
    // Room for the tallest bar + its count + the day label. The text part
    // grows with the user's text size, so nothing spills out of the card.
    final chartHeight = 130 + MediaQuery.textScalerOf(context).scale(44);

    return CustomCardContainer(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr('progress_week_chart_title'), style: AppTextStyles.titleSmall)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.tr('progress_week_total', {'count': '${cleansPerDay.fold<int>(0, (a, b) => a + b)}'}),
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryInk, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < cleansPerDay.length; i++)
                        Expanded(
                          child: _Bar(
                            value: cleansPerDay[i],
                            fraction: cleansPerDay[i] / maxValue,
                            isToday: i == cleansPerDay.length - 1,
                            delayMs: i * 70,
                            label: context.tr(
                              AppFunctions.weekdayShortKey(
                                DateTime(today.year, today.month, today.day - (6 - i)).weekday,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (cleansPerDay.every((count) => count == 0))
                  Align(
                    alignment: const Alignment(0, -0.35),
                    child: Text(
                      context.tr('progress_week_empty'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.fraction,
    required this.isToday,
    required this.delayMs,
    required this.label,
  });

  final int value;
  final double fraction;
  final bool isToday;
  final int delayMs;
  final String label;

  static const double _minBarHeight = 8;
  static const double _countGap = 4;

  @override
  Widget build(BuildContext context) {
    final countStyle = AppTextStyles.label.copyWith(color: AppColors.ink, letterSpacing: 0);
    return Column(
      children: [
        // The bar area takes whatever the day label leaves, and inside it the
        // bar is sized from the MEASURED height of its count label, so the
        // taller Arabic font can never push it past the card.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final countPainter = TextPainter(
                text: TextSpan(text: '$value', style: countStyle),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final countHeight = countPainter.height;
              countPainter.dispose();
              final maxBarHeight = (constraints.maxHeight - countHeight - _countGap).clamp(
                _minBarHeight,
                double.infinity,
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0) Text('$value', maxLines: 1, style: countStyle),
                  const SizedBox(height: _countGap),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: Duration(milliseconds: 700 + delayMs),
                    curve: Curves.easeOutCubic,
                    builder: (context, animated, _) => Container(
                      width: 22,
                      height: (maxBarHeight * animated).clamp(_minBarHeight, maxBarHeight),
                      decoration: BoxDecoration(
                        gradient: isToday ? AppGradients.primaryButton : null,
                        color: isToday ? null : AppColors.primary.withValues(alpha: fraction == 0 ? 0.15 : 0.45),
                        borderRadius: AppRadii.pillAll,
                        boxShadow: isToday ? AppShadows.primaryGlow(strength: 0.5) : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTextStyles.label.copyWith(
            color: isToday ? AppColors.primaryInk : AppColors.inkMuted,
            fontSize: 11,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

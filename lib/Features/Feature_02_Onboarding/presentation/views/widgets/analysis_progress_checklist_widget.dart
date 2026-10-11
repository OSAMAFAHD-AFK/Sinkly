import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// "We're analyzing…" moment: a glowing percentage ring + checklist items
/// that tick one by one. Builds anticipation before a reveal (steps 7 & 13).
class AnalysisProgressChecklistWidget extends StatefulWidget {
  const AnalysisProgressChecklistWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 2600),
  });

  final String title;
  final List<String> items;
  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<AnalysisProgressChecklistWidget> createState() => _AnalysisProgressChecklistWidgetState();
}

class _AnalysisProgressChecklistWidgetState extends State<AnalysisProgressChecklistWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = Curves.easeInOutCubic.transform(_controller.value);
          return Column(
            children: [
              SizedBox.square(
                dimension: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.primarySoft,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Text('${(value * 100).round()}%', style: AppTextStyles.title.copyWith(fontSize: 26)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(widget.title, style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < widget.items.length; i++)
                _ChecklistRow(label: widget.items[i], isDone: value >= (i + 1) / (widget.items.length + 0.4)),
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.96, 0.96));
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppDurations.medium,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: isDone
                ? const Icon(Icons.check_circle_rounded, key: ValueKey('done'), color: AppColors.success, size: 22)
                : const SizedBox.square(
                    key: ValueKey('loading'),
                    dimension: 22,
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.medium,
              style: AppTextStyles.bodyStrong.copyWith(
                color: isDone ? AppColors.ink : AppColors.inkMuted,
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

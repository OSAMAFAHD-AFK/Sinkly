import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/glass_bottom_sheet.dart';
import '../../manager/sink_unlock_cubit.dart';

/// Glass pill under the plan / tips: "⏱ Adjust timer · 5 minutes".
/// Opens [showSprintDurationSheet] and applies the pick to the cubit — works
/// before the sprint starts and while it is running.
class SprintDurationButtonWidget extends StatelessWidget {
  const SprintDurationButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final minutes = context.select((SinkUnlockCubit c) => c.state.sprintMinutes);
    final label = context.tr('sprint_adjust_cta', {'duration': context.minutes(minutes)});

    return Center(
      child: AnimatedPressableWidget(
        semanticLabel: label,
        onTap: () async {
          final picked = await showSprintDurationSheet(context, currentMinutes: minutes);
          if (picked != null && context.mounted) context.read<SinkUnlockCubit>().setSprintMinutes(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassFillStrong,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppColors.primaryInk),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk, fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryInk),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to choose the sprint length: − / + stepper for one-minute
/// changes plus quick picks. Returns the chosen minutes (null = dismissed).
Future<int?> showSprintDurationSheet(BuildContext context, {required int currentMinutes}) {
  return showGlassBottomSheet<int>(
    context: context,
    builder: (sheetContext) => _SprintDurationSheet(initialMinutes: currentMinutes),
  );
}

class _SprintDurationSheet extends StatefulWidget {
  const _SprintDurationSheet({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_SprintDurationSheet> createState() => _SprintDurationSheetState();
}

class _SprintDurationSheetState extends State<_SprintDurationSheet> {
  late int _minutes = widget.initialMinutes;

  void _set(int value) {
    final safe = value.clamp(AppConstants.minSprintMinutes, AppConstants.maxSprintMinutes);
    if (safe == _minutes) return;
    AppFunctions.selectionHaptic();
    setState(() => _minutes = safe);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr('sprint_duration_title'), textAlign: TextAlign.center, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(context.tr('sprint_duration_hint'), textAlign: TextAlign.center, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: context.tr('sprint_duration_less'),
                onTap: _minutes > AppConstants.minSprintMinutes ? () => _set(_minutes - 1) : null,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        context.minutes(_minutes),
                        key: ValueKey(_minutes),
                        style: AppTextStyles.display.copyWith(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: context.tr('sprint_duration_more'),
                onTap: _minutes < AppConstants.maxSprintMinutes ? () => _set(_minutes + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final preset in AppConstants.sprintPresetMinutes)
                _PresetChip(minutes: preset, selected: preset == _minutes, onTap: () => _set(preset)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomPrimaryButton(
            label: context.tr('sprint_duration_save'),
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(_minutes),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: tooltip,
      child: AnimatedPressableWidget(
        onTap: onTap,
        semanticLabel: tooltip,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: AppDurations.fast,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: AppShadows.soft,
            ),
            child: Icon(icon, color: AppColors.primaryInk, size: 26),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.minutes, required this.selected, required this.onTap});

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: context.minutes(minutes),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primaryButton : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.85),
          borderRadius: AppRadii.pillAll,
          border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder, width: 1.2),
        ),
        child: Text(
          context.tr('duration_minutes', {'m': '$minutes'}),
          style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, color: selected ? AppColors.onPrimary : AppColors.ink),
        ),
      ),
    );
  }
}

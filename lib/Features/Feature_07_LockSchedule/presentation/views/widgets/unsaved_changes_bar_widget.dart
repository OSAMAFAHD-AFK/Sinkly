import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';

/// Glass bar docked just above the tab bar; it rises from behind the nav bar
/// when the plan has unsaved edits and stays put while the plan scrolls.
class UnsavedChangesBarWidget extends StatelessWidget {
  const UnsavedChangesBarWidget({
    super.key,
    required this.visible,
    required this.isSaving,
    required this.canSave,
    required this.onSave,
    required this.onDiscard,
  });

  final bool visible;
  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    // Hidden bar slides over the nav bar area — it must not swallow taps.
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.6),
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AppDurations.medium,
          child: CustomCardContainer(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, 8, 8, 8),
            borderRadius: AppRadii.pillAll,
            fillColor: AppColors.glassFillStrong,
            useSharedBackdrop: false,
            child: Row(
              children: [
                // Soft pulsing amber dot = "pending" status.
                Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.6), blurRadius: 8)],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.75, end: 1.15, duration: 900.ms, curve: Curves.easeInOut),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('plan_unsaved_changes'),
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                  ),
                ),
                TextButton(onPressed: isSaving ? null : onDiscard, child: Text(context.tr('discard'))),
                SizedBox(
                  width: 120,
                  child: CustomPrimaryButton(
                    height: 46,
                    label: context.tr('save'),
                    isLoading: isSaving,
                    onPressed: canSave ? onSave : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

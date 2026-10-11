import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/blockable_app_model.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/custom_secondary_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../../../Feature_02_Onboarding/presentation/views/widgets/distracting_app_selection_tile_widget.dart';
import '../../../Feature_02_Onboarding/presentation/views/widgets/schedule_meal_picker_matrix_widget.dart';
import '../manager/lock_schedule_cubit.dart';
import 'widgets/unsaved_changes_bar_widget.dart';

/// Plan tab: edit lock days, meals, times and locked apps after onboarding.
class LockScheduleView extends StatelessWidget {
  const LockScheduleView({super.key});

  Future<void> _testLock(BuildContext context) async {
    final ok = await context.read<LockScheduleCubit>().triggerTestLockNow();
    if (!context.mounted || !ok) return;
    AppFunctions.mediumHaptic();
    context.push(AppRouter.kSinkUnlockView);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LockScheduleCubit>();
    final state = context.watch<LockScheduleCubit>().state;
    final draft = state.draft;

    return BlocListener<LockScheduleCubit, LockScheduleState>(
      listenWhen: (previous, current) => previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == LockScheduleSaveStatus.saved) {
          AppFunctions.successHaptic();
          AppFunctions.showSnack(context, context.tr('plan_saved'));
        } else if (state.saveStatus == LockScheduleSaveStatus.failure && state.failureKey != null) {
          AppFunctions.showSnack(context, context.tr(state.failureKey!));
        }
      },
      child: GlassScreenScaffold(
        body: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 200),
              children: [
                Text(context.tr('plan_screen_title'), style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text(context.tr('plan_screen_subtitle'), style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
                ScheduleMealPickerMatrixWidget(
                  schedule: draft.schedule,
                  onDayToggled: cubit.toggleDay,
                  onPresetToggled: cubit.togglePreset,
                  onMealCountChanged: cubit.setMealCount,
                  onMealTimeChanged: cubit.setMealTime,
                  onSyncAllDaysWith: cubit.syncAllDaysWith,
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeaderWidget(title: context.tr('plan_apps_section'), leadingNumber: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: BlockableAppModel.catalog.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: 66,
                  ),
                  itemBuilder: (context, index) {
                    final app = BlockableAppModel.catalog[index];
                    return DistractingAppSelectionTileWidget(
                      app: app,
                      isSelected: draft.blockedAppIds.contains(app.id),
                      onTap: () => cubit.toggleApp(app.id),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeaderWidget(title: context.tr('plan_try_section')),
                CustomSecondaryButton(
                  label: context.tr('plan_test_lock_cta'),
                  icon: const Icon(Icons.bolt_rounded),
                  onPressed: () => _testLock(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('plan_test_lock_hint'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ].animate(interval: 40.ms).fadeIn(duration: 350.ms).slideY(begin: 0.04),
            ),
            Positioned(
              left: AppSpacing.screenGutter,
              right: AppSpacing.screenGutter,
              bottom: 100 + MediaQuery.paddingOf(context).bottom,
              child: UnsavedChangesBarWidget(
                visible: state.hasUnsavedChanges,
                isSaving: state.saveStatus == LockScheduleSaveStatus.saving,
                canSave: draft.isValid,
                onSave: cubit.save,
                onDiscard: cubit.discardChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

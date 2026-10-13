import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/custom_secondary_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../../Feature_02_Onboarding/presentation/views/widgets/schedule_meal_picker_matrix_widget.dart';
import '../manager/lock_schedule_cubit.dart';
import 'widgets/unsaved_changes_bar_widget.dart';
import '../../../../core/widgets/app_category_picker_widget.dart';
import '../../../../core/widgets/system_app_picker_widget.dart';

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
                  onMealCountChanged: cubit.setMealCount,
                  onMealTimeChanged: cubit.setMealTime,
                  onSyncAllDaysWith: cubit.syncAllDaysWith,
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeaderWidget(title: context.tr('plan_apps_section')),
                // Same Screen-Time-style picker as onboarding (Apple's on iOS).
                if (cubit.appPickerMode == AppPickerMode.systemPicker)
                  SystemAppPickerWidget(
                    height: MediaQuery.sizeOf(context).height * 0.55,
                    onCountChanged: (picked) =>
                        cubit.updateAppSelection(draft.appSelection.copyWith(systemPickerCount: picked)),
                  )
                else
                  AppCategoryPickerWidget(
                    apps: state.installedApps,
                    selection: draft.appSelection,
                    isLoading: !state.appsLoaded,
                    onChanged: cubit.updateAppSelection,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/app_category_picker_widget.dart';
import '../../../../../core/widgets/system_app_picker_widget.dart';
import '../../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 9 — Select the apps that steal your time, Screen-Time style:
/// whole categories or single apps.
///
/// * Android: the apps installed on this phone, grouped by category.
/// * iOS: Apple's own FamilyActivityPicker embedded here (iOS never lets an
///   app list installed apps); only the number of picks comes back.
class DistractingAppsSelectionStepWidget extends StatelessWidget {
  const DistractingAppsSelectionStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final selection = context.select((OnboardingCubit c) => c.state.preferences.appSelection);
    final apps = context.select((OnboardingCubit c) => c.state.installedApps);
    final appsLoaded = context.select((OnboardingCubit c) => c.state.appsLoaded);
    final count = selection.selectedCount(apps);
    final systemPicker = cubit.appPickerMode == AppPickerMode.systemPicker;

    return OnboardingStepScaffoldWidget(
      title: context.tr('apps_title'),
      description: context.tr('apps_description'),
      ctaLabel: count == 0 ? context.tr('apps_cta') : '${context.tr('apps_cta')} ($count)',
      onCtaPressed: count == 0 ? null : cubit.nextStep,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (systemPicker)
            SystemAppPickerWidget(
              height: MediaQuery.sizeOf(context).height * 0.58,
              onCountChanged: (picked) => cubit.updateAppSelection(selection.copyWith(systemPickerCount: picked)),
            )
          else
            AppCategoryPickerWidget(
              apps: apps,
              selection: selection,
              isLoading: !appsLoaded,
              onChanged: cubit.updateAppSelection,
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(context.tr('apps_privacy_note'), style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

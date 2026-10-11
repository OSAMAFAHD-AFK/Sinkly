import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../manager/onboarding_cubit.dart';
import 'distracting_app_selection_tile_widget.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 9 — Select the apps that steal your time.
class DistractingAppsSelectionStepWidget extends StatelessWidget {
  const DistractingAppsSelectionStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final selectedIds = context.select((OnboardingCubit c) => c.state.preferences.blockedAppIds);

    return OnboardingStepScaffoldWidget(
      title: context.tr('apps_title'),
      description: context.tr('apps_description'),
      ctaLabel: selectedIds.isEmpty ? context.tr('apps_cta') : '${context.tr('apps_cta')} (${selectedIds.length})',
      onCtaPressed: selectedIds.isEmpty ? null : cubit.nextStep,
      body: Column(
        children: [
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
                    isSelected: selectedIds.contains(app.id),
                    onTap: () => cubit.toggleBlockedApp(app.id),
                  )
                  .animate(delay: (50 * index).ms)
                  .fadeIn(duration: 300.ms)
                  .scaleXY(begin: 0.94, curve: Curves.easeOutBack);
            },
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../../../core/widgets/dev_shortcut_button_widget.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../Feature_06_SinkUnlock/presentation/views/SinkUnlockView.dart';
import '../manager/lock_overlay_cubit.dart';
import 'widgets/lock_overlay_heroine_stage_widget.dart';
import 'widgets/lock_overlay_reward_strip_widget.dart';
import 'widgets/locked_app_chip_widget.dart';

/// Shown when a locked app is opened after a meal: the heroine cheers the
/// user up off the couch instead of a cold "blocked" wall. The only real way
/// through is the sink sprint (or a photo of an already clean sink).
///
/// Native plan: on Android the blocker service opens this route (Flutter
/// activity over the blocked app); on iOS the system Shield can't host
/// Flutter, so its ShieldConfiguration mirrors this copy and its button
/// deep-links here.
class LockOverlayView extends StatelessWidget {
  const LockOverlayView({super.key});

  void _leave(BuildContext context) => context.canPop() ? context.pop() : context.go(AppRouter.kHomeView);

  void _startSprint(BuildContext context) {
    AppFunctions.mediumHaptic();
    context.pushReplacement(AppRouter.kSinkUnlockView);
  }

  void _snapPhoto(BuildContext context) {
    AppFunctions.lightHaptic();
    context.pushReplacement(AppRouter.kSinkUnlockView, extra: SinkUnlockView.openCameraExtra);
  }

  // TODO(dev): remove with AppConstants.showDevLockBypass before release.
  void _devBypass(BuildContext context) {
    AppFunctions.lightHaptic();
    AppFunctions.showSnack(context, context.tr('lock_overlay_dev_bypassed'));
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select((LockOverlayCubit cubit) => cubit.state.snapshot);
    final appName = snapshot.attemptedApp?.displayName ?? context.tr('lock_overlay_apps_generic');
    final duration = context.minutes(snapshot.sprintMinutes);
    final titleKey = switch (snapshot.lockingMeal) {
      MealType.breakfast => 'lock_overlay_title_breakfast',
      MealType.lunch => 'lock_overlay_title_lunch',
      MealType.dinner => 'lock_overlay_title_dinner',
      null => 'lock_overlay_title_manual',
    };

    // A real overlay can't be "backed out of"; the way through is the sink.
    return PopScope(
      canPop: false,
      child: GlassScreenScaffold(
        palette: MeshPalette.warm,
        animateBackground: true,
        body: LayoutBuilder(
          builder: (context, box) {
            // The stage takes whatever the text and buttons leave; on short
            // phones / huge text it keeps a minimum and the page scrolls.
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stageHeight = (box.maxHeight - (250 + 230 * textScale)).clamp(210.0, 360.0);
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.xs,
                    AppSpacing.screenGutter,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: LockedAppChipWidget(app: snapshot.attemptedApp),
                            ),
                          ),
                          if (AppConstants.showDevLockBypass) ...[
                            const SizedBox(width: AppSpacing.xs),
                            DevShortcutButtonWidget(
                              label: context.tr('lock_overlay_dev_bypass'),
                              onPressed: () => _devBypass(context),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: stageHeight, child: const LockOverlayHeroineStageWidget())
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scaleXY(begin: 0.92, curve: Curves.easeOutBack, duration: 700.ms),
                      Column(
                        children: [
                          Text(context.tr(titleKey), textAlign: TextAlign.center, style: AppTextStyles.headline)
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr('lock_overlay_subtitle', {'app': appName}),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body,
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: AppSpacing.md),
                          LockOverlayRewardStripWidget(snapshot: snapshot),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          children: [
                            CustomPrimaryButton(
                              label: context.tr('lock_overlay_cta', {'duration': duration}),
                              icon: Icons.bolt_rounded,
                              showShimmer: true,
                              onPressed: () => _startSprint(context),
                            ).animate(delay: 700.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
                            TextButton(
                              onPressed: () => _snapPhoto(context),
                              child: Text(
                                context.tr('lock_overlay_already_clean'),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/sink_progress_stats_model.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../manager/sink_unlock_cubit.dart';
import 'widgets/photo_verification_scanning_widget.dart';
import 'widgets/sink_sprint_stage_widget.dart';
import 'widgets/sink_unlock_intro_stage_widget.dart';
import 'widgets/unlock_reward_celebration_widget.dart';

/// Full-screen unlock flow: intro → sprint → photo verification → reward.
class SinkUnlockView extends StatelessWidget {
  const SinkUnlockView({super.key});

  void _close(BuildContext context) => context.canPop() ? context.pop() : context.go(AppRouter.kHomeView);

  @override
  Widget build(BuildContext context) {
    final stage = context.select((SinkUnlockCubit c) => c.state.stage);

    return BlocListener<SinkUnlockCubit, SinkUnlockState>(
      listenWhen: (previous, current) =>
          (current.failureKey != null && previous.failureKey != current.failureKey) ||
          (previous.stage != current.stage && current.stage == SinkUnlockStage.celebrating),
      listener: (context, state) {
        if (state.stage == SinkUnlockStage.celebrating && state.failureKey == null) {
          AppFunctions.successHaptic();
          return;
        }
        if (state.failureKey != null) {
          AppFunctions.showSnack(context, context.tr(state.failureKey!));
          context.read<SinkUnlockCubit>().clearFailure();
        }
      },
      child: PopScope(
        // Don't allow leaving mid-verification.
        canPop: stage != SinkUnlockStage.verifying,
        child: GlassScreenScaffold(
          animateBackground: stage == SinkUnlockStage.celebrating,
          palette: stage == SinkUnlockStage.celebrating ? MeshPalette.fresh : MeshPalette.sky,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: stage == SinkUnlockStage.verifying || stage == SinkUnlockStage.celebrating ? 0 : 1,
                      duration: AppDurations.medium,
                      child: GlassIconButton(
                        icon: Icons.close_rounded,
                        semanticLabel: context.tr('close'),
                        onPressed: stage == SinkUnlockStage.verifying ? null : () => _close(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.tr('unlock_screen_title'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.slow,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(stage), child: _buildStage(context, stage)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context, SinkUnlockStage stage) {
    final state = context.read<SinkUnlockCubit>().state;
    return switch (stage) {
      SinkUnlockStage.intro => const SinkUnlockIntroStageWidget(),
      SinkUnlockStage.sprinting => const SinkSprintStageWidget(),
      SinkUnlockStage.verifying => PhotoVerificationScanningWidget(photoPath: state.photoPath ?? ''),
      SinkUnlockStage.celebrating => UnlockRewardCelebrationWidget(
        session: state.completedSession!,
        stats: state.statsAfterUnlock ?? SinkProgressStatsModel.empty,
        unlockedApps: state.blockedApps,
        onDone: () => _close(context),
      ),
    };
  }
}

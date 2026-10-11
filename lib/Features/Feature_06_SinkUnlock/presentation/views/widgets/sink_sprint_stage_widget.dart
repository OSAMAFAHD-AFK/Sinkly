import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../manager/sink_unlock_cubit.dart';
import 'sink_sprint_countdown_ring_widget.dart';

/// Stage 2 — the 4-minute sprint: water-fill countdown + rotating pro tips +
/// "Done! Snap the clean sink" CTA (available any time).
class SinkSprintStageWidget extends StatelessWidget {
  const SinkSprintStageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SinkUnlockCubit>();
    final remaining = context.select((SinkUnlockCubit c) => c.state.remainingSeconds);
    final progress = context.select((SinkUnlockCubit c) => c.state.sprintProgress);
    final isCapturing = context.select((SinkUnlockCubit c) => c.state.isCapturing);
    final finished = remaining <= 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr(finished ? 'sprint_title_done' : 'sprint_title'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(context.tr('sprint_subtitle'), textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
                SinkSprintCountdownRingWidget(
                  progress: progress,
                  remainingSeconds: remaining,
                  caption: context.tr(finished ? 'sprint_time_up' : 'sprint_remaining'),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _RotatingTipsCard(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.xs,
            AppSpacing.screenGutter,
            AppSpacing.md,
          ),
          child: CustomPrimaryButton(
            label: context.tr('sprint_snap_cta'),
            icon: Icons.photo_camera_rounded,
            showShimmer: finished,
            isLoading: isCapturing,
            onPressed: cubit.captureAndVerifyPhoto,
          ),
        ),
      ],
    );
  }
}

class _RotatingTipsCard extends StatefulWidget {
  const _RotatingTipsCard();

  @override
  State<_RotatingTipsCard> createState() => _RotatingTipsCardState();
}

class _RotatingTipsCardState extends State<_RotatingTipsCard> {
  static const _tipKeys = ['sprint_tip_1', 'sprint_tip_2', 'sprint_tip_3', 'sprint_tip_4'];
  int _index = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _tipKeys.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.slow,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Align(
                key: ValueKey(_index),
                alignment: AlignmentDirectional.centerStart,
                child: Text(context.tr(_tipKeys[_index]), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

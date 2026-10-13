import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 10 — Screen Time permission. Shows a friendly preview of the
/// system dialog before triggering the real request (mocked in
/// [DevicePermissionsDataSource] for now).
class ScreenTimePermissionStepWidget extends StatelessWidget {
  const ScreenTimePermissionStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final status = context.select((OnboardingCubit c) => c.state.permissionStatus);
    final justGranted = status == OnboardingRequestStatus.success;
    // Returning to this step after granting earlier must not block the user.
    final alreadyGranted =
        context.select((OnboardingCubit c) => c.state.preferences.screenTimePermissionGranted) && !justGranted;
    final isGranted = justGranted || alreadyGranted;

    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.permissionStatus != current.permissionStatus &&
          current.permissionStatus == OnboardingRequestStatus.success,
      listener: (context, state) async {
        AppFunctions.successHaptic();
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (context.mounted) cubit.nextStep();
      },
      child: OnboardingStepScaffoldWidget(
        illustration: _PermissionDialogPreview(isGranted: isGranted),
        title: context.tr('permission_title'),
        description: context.tr('permission_description'),
        headerAlign: TextAlign.center,
        ctaLabel: justGranted
            ? context.tr('permission_granted')
            : alreadyGranted
            ? context.tr('continue')
            : context.tr('permission_cta'),
        isCtaLoading: status == OnboardingRequestStatus.inProgress,
        onCtaPressed: justGranted
            ? null
            : alreadyGranted
            ? cubit.nextStep
            : cubit.requestScreenTimePermission,
        secondaryAction: isGranted
            ? null
            : TextButton(
                onPressed: cubit.nextStep,
                child: Text(
                  context.tr('maybe_later'),
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }
}

class _PermissionDialogPreview extends StatelessWidget {
  const _PermissionDialogPreview({required this.isGranted});

  final bool isGranted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.xl),
      child: SizedBox(
        width: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomCardContainer(
              fillColor: AppColors.glassFillStrong,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8E7CFF), Color(0xFF5B4BDB)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('permission_dialog_title'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('permission_dialog_body'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              context.tr('permission_dialog_deny'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.inkMuted),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              context.tr('permission_dialog_allow'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Pointing hand on "Continue" — or a success badge once granted.
            PositionedDirectional(
              end: 30,
              bottom: -24,
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: isGranted
                    ? Container(
                        key: const ValueKey('granted'),
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: AppGradients.success,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                      )
                    : const Text('👆', key: ValueKey('hand'), style: TextStyle(fontSize: 34))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -8, duration: 700.ms, curve: Curves.easeInOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

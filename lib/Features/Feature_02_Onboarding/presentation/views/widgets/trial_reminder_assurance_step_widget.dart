import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../manager/onboarding_cubit.dart';
import 'onboarding_step_scaffold_widget.dart';

/// Screen 14 — Pre-paywall assurance: a transparent trial timeline and a
/// promise to remind the user 24h before the trial ends (reduces anxiety,
/// increases trial starts).
class TrialReminderAssuranceStepWidget extends StatelessWidget {
  const TrialReminderAssuranceStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final isRequesting = context.select(
      (OnboardingCubit c) => c.state.permissionStatus == OnboardingRequestStatus.inProgress,
    );
    const trialDays = AppConstants.freeTrialDays;

    return OnboardingStepScaffoldWidget(
      illustration: const GlassIconOrbWidget(icon: Icons.notifications_active_rounded, size: 96)
          .animate(onPlay: (c) => c.repeat(), delay: 600.ms)
          .shake(hz: 4, rotation: 0.06, duration: 700.ms)
          // No-op effect that adds a pause between rings.
          .then()
          .scaleXY(begin: 1, end: 1, duration: 1800.ms),
      title: context.tr('trial_reminder_title'),
      description: context.tr('trial_reminder_description'),
      ctaLabel: context.tr('trial_reminder_cta'),
      isCtaLoading: isRequesting,
      onCtaPressed: cubit.acceptTrialReminder,
      body: CustomCardContainer(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
        child: Column(
          children:
              [
                    _TimelineRow(
                      icon: Icons.lock_open_rounded,
                      title: context.tr('trial_timeline_today_title'),
                      subtitle: context.tr('trial_timeline_today_subtitle'),
                      isHighlighted: true,
                    ),
                    _TimelineRow(
                      icon: Icons.notifications_rounded,
                      title: context.tr('trial_timeline_reminder_title', {'day': '${trialDays - 1}'}),
                      subtitle: context.tr('trial_timeline_reminder_subtitle'),
                    ),
                    _TimelineRow(
                      icon: Icons.star_rounded,
                      title: context.tr('trial_timeline_end_title', {'day': '$trialDays'}),
                      subtitle: context.tr('trial_timeline_end_subtitle'),
                      isLast: true,
                    ),
                  ]
                  .animate(interval: 160.ms, delay: 250.ms)
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: context.flipX(0.08), curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isHighlighted = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isHighlighted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isHighlighted ? AppGradients.primaryButton : null,
                  color: isHighlighted ? null : AppColors.primarySoft,
                  boxShadow: isHighlighted ? AppShadows.primaryGlow(strength: 0.5) : null,
                ),
                child: Icon(icon, size: 20, color: isHighlighted ? AppColors.onPrimary : AppColors.primaryInk),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadii.pillAll),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

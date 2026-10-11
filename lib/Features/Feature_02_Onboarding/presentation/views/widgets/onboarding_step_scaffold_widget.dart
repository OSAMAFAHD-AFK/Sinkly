import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import 'onboarding_step_header_widget.dart';

/// Shared layout for onboarding steps:
///   illustration → headline/description → body (scrollable) → sticky CTA.
/// Every block enters with a short staggered fade/slide for a premium feel.
class OnboardingStepScaffoldWidget extends StatelessWidget {
  const OnboardingStepScaffoldWidget({
    super.key,
    required this.title,
    required this.ctaLabel,
    required this.onCtaPressed,
    this.description,
    this.highlight,
    this.illustration,
    this.body,
    this.isCtaLoading = false,
    this.showCtaShimmer = false,
    this.ctaIcon,
    this.secondaryAction,
    this.headerAlign = TextAlign.center,
    this.customCta,
  });

  final String title;
  final String? description;
  final String? highlight;
  final Widget? illustration;
  final Widget? body;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;
  final bool isCtaLoading;
  final bool showCtaShimmer;
  final IconData? ctaIcon;
  final Widget? secondaryAction;
  final TextAlign headerAlign;

  /// Replaces the default primary button (e.g. hold-to-commit on screen 12).
  final Widget? customCta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              AppSpacing.md,
              AppSpacing.screenGutter,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (illustration != null)
                  Center(child: illustration!)
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack, duration: 600.ms),
                OnboardingStepHeaderWidget(
                  title: title,
                  description: description,
                  highlight: highlight,
                  textAlign: headerAlign,
                ).animate(delay: 90.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  body!.animate(delay: 180.ms).fadeIn(duration: 420.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customCta ??
                  CustomPrimaryButton(
                    label: ctaLabel,
                    onPressed: onCtaPressed,
                    isLoading: isCtaLoading,
                    showShimmer: showCtaShimmer,
                    trailingIcon: ctaIcon,
                  ),
              if (secondaryAction != null) ...[const SizedBox(height: AppSpacing.xs), secondaryAction!],
            ],
          ).animate(delay: 260.ms).fadeIn(duration: 400.ms).slideY(begin: 0.25, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

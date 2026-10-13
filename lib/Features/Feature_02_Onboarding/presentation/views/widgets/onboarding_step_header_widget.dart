import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';

/// Headline + supporting copy for each onboarding step.
/// Titles and subtitles are centered across the whole onboarding funnel.
/// If [highlight] (usually the user's name) appears in the title it is
/// painted in brand sky blue to make the message feel personal.
class OnboardingStepHeaderWidget extends StatelessWidget {
  const OnboardingStepHeaderWidget({
    super.key,
    required this.title,
    this.description,
    this.highlight,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final String? description;
  final String? highlight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final crossAxis = textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text.rich(_buildTitleSpan(), textAlign: textAlign, style: AppTextStyles.headline),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(description!, textAlign: textAlign, style: AppTextStyles.body),
        ],
      ],
    );
  }

  TextSpan _buildTitleSpan() {
    final name = highlight?.trim() ?? '';
    final index = name.isEmpty ? -1 : title.indexOf(name);
    if (index < 0) return TextSpan(text: title);
    return TextSpan(
      children: [
        TextSpan(text: title.substring(0, index)),
        TextSpan(
          text: name,
          style: const TextStyle(color: AppColors.primaryInk),
        ),
        TextSpan(text: title.substring(index + name.length)),
      ],
    );
  }
}

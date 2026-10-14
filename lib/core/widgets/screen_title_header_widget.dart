import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Centered screen title (+ optional subtitle) for the main tab headers.
class ScreenTitleHeaderWidget extends StatelessWidget {
  const ScreenTitleHeaderWidget({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.headline),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, textAlign: TextAlign.center, style: AppTextStyles.body),
        ],
      ],
    );
  }
}

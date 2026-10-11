import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Small uppercase label + optional trailing action used to title sections.
class SectionHeaderWidget extends StatelessWidget {
  const SectionHeaderWidget({super.key, required this.title, this.trailing, this.leadingNumber});

  final String title;
  final Widget? trailing;

  /// Optional step number bubble ("1", "2", "3") for multi-part forms.
  final int? leadingNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4, bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (leadingNumber != null) ...[
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Text(
                '$leadingNumber',
                style: AppTextStyles.label.copyWith(color: AppColors.primaryInk, letterSpacing: 0),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(child: Text(title.toUpperCase(), style: AppTextStyles.label)),
          ?trailing,
        ],
      ),
    );
  }
}

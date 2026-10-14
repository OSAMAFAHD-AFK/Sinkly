import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';

/// App logo + name + account label + edit button.
class SettingsProfileCardWidget extends StatelessWidget {
  const SettingsProfileCardWidget({
    super.key,
    required this.userName,
    required this.accountLabel,
    required this.onEditName,
  });

  final String userName;
  final String accountLabel;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      // Compact phones / large text: the edit button collapses to an icon so
      // the name keeps enough room instead of breaking letter by letter.
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _buildRow(context, compact: constraints.maxWidth < 270 || MediaQuery.textScalerOf(context).scale(1) > 1.15),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required bool compact}) {
    return Row(
      children: [
        const SinklyLogoWidget(size: 34, showWordmark: false),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isEmpty ? context.tr('home_greeting_fallback') : userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 2),
              Text(accountLabel, style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ],
          ),
        ),
        if (compact)
          IconButton(
            onPressed: onEditName,
            tooltip: context.tr('edit'),
            color: AppColors.primaryInk,
            icon: const Icon(Icons.edit_rounded, size: 20),
          )
        else
          TextButton.icon(
            onPressed: onEditName,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(context.tr('edit')),
          ),
      ],
    );
  }
}

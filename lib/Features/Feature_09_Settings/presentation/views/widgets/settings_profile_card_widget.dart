import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Avatar + name + account label + edit button.
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: AppShadows.primaryGlow(strength: 0.5),
            ),
            child: Text(
              AppFunctions.initialOf(userName),
              style: AppTextStyles.headline.copyWith(color: AppColors.onPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName.isEmpty ? context.tr('home_greeting_fallback') : userName, style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text(accountLabel, style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEditName,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(context.tr('edit')),
          ),
        ],
      ),
    );
  }
}

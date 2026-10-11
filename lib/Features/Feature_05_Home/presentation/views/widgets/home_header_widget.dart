import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';

/// Greeting row: avatar bubble · "Good evening, Sara" · brand badge.
class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key, required this.userName, required this.now});

  final String userName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: AppShadows.primaryGlow(strength: 0.5),
          ),
          child: Text(
            AppFunctions.initialOf(userName),
            style: AppTextStyles.title.copyWith(color: AppColors.onPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(AppFunctions.greetingKey(now)), style: AppTextStyles.caption),
              Text(
                userName.isEmpty ? context.tr('home_greeting_fallback') : userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
            ],
          ),
        ),
        const SinklyLogoWidget(size: 22, showWordmark: false),
      ],
    );
  }
}

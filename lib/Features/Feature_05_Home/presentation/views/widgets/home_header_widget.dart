import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';

/// Centered greeting + username with brand mark on the leading side
/// (left in English / right in Arabic via [Directionality]).
class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key, required this.userName, required this.now});

  final String userName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isEmpty ? context.tr('home_greeting_fallback') : userName;

    return Column(
      children: [
        Text(
          context.tr(AppFunctions.greetingKey(now)),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 4),
        // Logo leads the row: left in LTR (EN), right in RTL (AR).
        LayoutBuilder(
          builder: (context, constraints) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SinklyLogoWidget(size: 22, showWordmark: false),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.7),
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

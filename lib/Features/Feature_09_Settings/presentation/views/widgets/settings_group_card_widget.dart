import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/section_header_widget.dart';

/// Titled glass group of settings rows separated by hairline dividers.
class SettingsGroupCardWidget extends StatelessWidget {
  const SettingsGroupCardWidget({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeaderWidget(title: title),
        CustomCardContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 50),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

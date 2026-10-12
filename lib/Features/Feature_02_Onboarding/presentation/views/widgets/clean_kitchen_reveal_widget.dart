import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import 'kitchen_transformation_scene_widget.dart';

/// Screen 4 hero: the sink starts messy, then — as the user reads — transforms
/// into a sparkling clean kitchen. The reveal IS the message ("what a clean
/// kitchen feels like"), followed by three feeling chips.
class CleanKitchenRevealWidget extends StatelessWidget {
  const CleanKitchenRevealWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final chips = [
      context.tr('reality_chip_clear_mind'),
      context.tr('reality_chip_no_guilt'),
      context.tr('reality_chip_fresh_start'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KitchenTransformationSceneWidget(),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, label) in chips.indexed)
              Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: AppRadii.pillAll,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.floating,
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                    ),
                  )
                  // Chips pop in right after the sink turns clean.
                  .animate(delay: (3000 + index * 260).ms)
                  .fadeIn(duration: 350.ms)
                  .scaleXY(begin: 0.6, curve: Curves.easeOutBack, duration: 500.ms),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

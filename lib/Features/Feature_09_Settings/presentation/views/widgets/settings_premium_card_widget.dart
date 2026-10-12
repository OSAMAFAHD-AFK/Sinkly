import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';

/// Premium status: an active badge, or a glowing upsell card.
class SettingsPremiumCardWidget extends StatelessWidget {
  const SettingsPremiumCardWidget({super.key, required this.isPremium, required this.onUpgrade});

  final bool isPremium;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    // Compact phones / large text: the CTA pill moves under the copy so the
    // title never breaks mid-word.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildCard(context, stackCta: constraints.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.15),
    );
  }

  Widget _buildCard(BuildContext context, {required bool stackCta}) {
    final cta = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: AppRadii.pillAll, boxShadow: AppShadows.soft),
      child: Text(
        context.tr('settings_premium_upsell_cta'),
        style: AppTextStyles.label.copyWith(color: AppColors.onPrimary, letterSpacing: 0.2),
      ),
    );

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        gradient: isPremium ? AppGradients.ink : AppGradients.primaryButton,
        borderRadius: AppRadii.cardAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
        boxShadow: isPremium ? AppShadows.floating : AppShadows.primaryGlow(strength: 0.8),
      ),
      child: Row(
        children: [
          Text(isPremium ? '💎' : '✨', style: const TextStyle(fontSize: 34)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(isPremium ? 'settings_premium_active_title' : 'settings_premium_upsell_title'),
                  style: AppTextStyles.titleSmall.copyWith(color: isPremium ? Colors.white : AppColors.onPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(isPremium ? 'settings_premium_active_subtitle' : 'settings_premium_upsell_subtitle'),
                  style: AppTextStyles.caption.copyWith(
                    color: isPremium ? Colors.white70 : AppColors.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
                if (!isPremium && stackCta) ...[const SizedBox(height: AppSpacing.sm), cta],
              ],
            ),
          ),
          if (!isPremium && !stackCta) cta,
        ],
      ),
    );

    if (isPremium) return card;
    return AnimatedPressableWidget(
      onTap: onUpgrade,
      semanticLabel: context.tr('settings_premium_upsell_title'),
      child: card
          .animate(onPlay: (c) => c.repeat())
          .shimmer(delay: 2500.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.45)),
    );
  }
}

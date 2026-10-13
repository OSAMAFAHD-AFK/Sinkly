import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';

/// Android's version of the permission "popup": Android has no system card
/// for app blocking, so Sinkly shows its OWN card in the same glowing frame
/// iOS uses. It is clearly Sinkly-branded (logo, Sinkly copy, brand pills),
/// never dressed up as an Android system dialog (Google Play policy), and it
/// doubles as the prominent disclosure Play asks for before Usage access.
///
/// "Continue" sits on the start side, like Apple's, so the pointer arrow
/// works the same on both platforms.
class SinklyPermissionCardWidget extends StatelessWidget {
  const SinklyPermissionCardWidget({super.key, required this.onAllow, required this.onLater});

  final VoidCallback onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md + 2, AppSpacing.lg - 4, AppSpacing.md + 2, AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App-icon badge.
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.primarySoft, width: 1.5),
              boxShadow: AppShadows.primaryGlow(strength: 0.45),
            ),
            child: const SinklyLogoWidget(size: 24, showWordmark: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('permission_card_title'),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(context.tr('permission_card_body'), textAlign: TextAlign.center, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CardPillButton(label: context.tr('permission_card_allow'), isPrimary: true, onTap: onAllow),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _CardPillButton(label: context.tr('permission_card_later'), isPrimary: false, onTap: onLater),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPillButton extends StatelessWidget {
  const _CardPillButton({required this.label, required this.isPrimary, required this.onTap});

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: isPrimary ? AppGradients.primaryButton : null,
        color: isPrimary ? null : AppColors.ink.withValues(alpha: 0.05),
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: AppTextStyles.button.copyWith(fontSize: 14, color: isPrimary ? AppColors.onPrimary : AppColors.inkSoft),
      ),
    );

    return AnimatedPressableWidget(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: label,
      child: isPrimary
          // Breathing glow on "Continue": the one thing to tap.
          ? pill
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .custom(
                  duration: 1100.ms,
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.pillAll,
                      boxShadow: AppShadows.primaryGlow(strength: 0.35 + 0.45 * value),
                    ),
                    child: child,
                  ),
                )
          : pill,
    );
  }
}

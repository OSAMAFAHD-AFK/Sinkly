import 'package:flutter/material.dart';

import '../../../../../core/models/supported_language_model.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Glass language card: flag, native name, English name, selection check.
/// Reused by onboarding (screen 1) and the Settings language sheet.
class LanguageCardSelectionWidget extends StatelessWidget {
  const LanguageCardSelectionWidget({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
    this.isDeviceLanguage = false,
    this.deviceBadgeLabel,
  });

  final SupportedLanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDeviceLanguage;
  final String? deviceBadgeLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: language.englishName,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          borderRadius: AppRadii.mediumAll,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.38),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: CustomCardContainer(
          borderRadius: AppRadii.mediumAll,
          fillColor: isSelected ? AppColors.primarySoft.withValues(alpha: 0.92) : AppColors.glassFill,
          borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
          borderWidth: isSelected ? 1.8 : 1.2,
          shadows: AppShadows.soft,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          child: Row(
            children: [
              Text(language.flagEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.nativeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(fontSize: 15),
                    ),
                    Text(
                      isDeviceLanguage && deviceBadgeLabel != null ? deviceBadgeLabel! : language.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        color: isDeviceLanguage ? AppColors.primaryInk : AppColors.inkMuted,
                        fontWeight: isDeviceLanguage ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: AppDurations.fast,
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryInk, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

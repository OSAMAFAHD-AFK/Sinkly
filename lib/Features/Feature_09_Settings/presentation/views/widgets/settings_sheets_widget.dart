import 'package:flutter/material.dart';

import '../../../../../core/models/supported_language_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/glass_bottom_sheet.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/language_card_selection_widget.dart';

/// Glass sheet with the 10 language cards. Returns the chosen code.
Future<String?> showLanguagePickerSheet(BuildContext context, {required String currentCode}) {
  return showGlassBottomSheet<String>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sheetContext.tr('choose_language_title'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: SupportedLanguageModel.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 64,
              ),
              itemBuilder: (context, index) {
                final language = SupportedLanguageModel.all[index];
                return LanguageCardSelectionWidget(
                  language: language,
                  isSelected: language.code == currentCode,
                  onTap: () => Navigator.of(sheetContext).pop(language.code),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Glass sheet with a name field. Returns the new name.
Future<String?> showEditNameSheet(BuildContext context, {required String currentName}) {
  final controller = TextEditingController(text: currentName);
  return showGlassBottomSheet<String>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sheetContext.tr('settings_edit_name_title'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            hintText: sheetContext.tr('name_hint'),
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
          ),
          const SizedBox(height: AppSpacing.md),
          CustomPrimaryButton(
            label: sheetContext.tr('save'),
            onPressed: () => Navigator.of(sheetContext).pop(controller.text),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Destructive confirmation for "Reset Sinkly".
Future<bool> showResetConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardAll),
      title: Text(dialogContext.tr('settings_reset_title'), style: AppTextStyles.title),
      content: Text(dialogContext.tr('settings_reset_message'), style: AppTextStyles.body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.tr('cancel'))),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(dialogContext.tr('settings_reset_confirm'), style: const TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/supported_language_model.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import '../manager/settings_cubit.dart';
import 'widgets/settings_group_card_widget.dart';
import 'widgets/settings_premium_card_widget.dart';
import 'widgets/settings_profile_card_widget.dart';
import 'widgets/settings_sheets_widget.dart';
import 'widgets/settings_tile_widget.dart';

/// Settings tab: profile, premium, preferences, community, account, reset.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _restore(BuildContext context) async {
    final restored = await context.read<SubscriptionCubit>().restorePurchases();
    if (context.mounted && restored) AppFunctions.showSnack(context, context.tr('restore_success'));
  }

  Future<void> _reset(BuildContext context) async {
    if (!await showResetConfirmationDialog(context) || !context.mounted) return;
    final done = await context.read<SettingsCubit>().resetApp();
    if (done && context.mounted) context.go(AppRouter.kSplashView);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final preferences = context.select((SettingsCubit c) => c.state.preferences);
    final isRequestingPermission = context.select((SettingsCubit c) => c.state.isRequestingPermission);
    final isPremium = context.select((SubscriptionCubit c) => c.state.isPremium);

    final sections = <Widget>[
      Text(context.tr('settings_screen_title'), style: AppTextStyles.headline),
      const SizedBox(height: AppSpacing.lg),
      SettingsProfileCardWidget(
        userName: preferences.userName,
        // No accounts: the subscription lives on the Apple / Google account.
        accountLabel: context.tr(isPremium ? 'settings_profile_premium' : 'settings_profile_member'),
        onEditName: () async {
          final name = await showEditNameSheet(context, currentName: preferences.userName);
          if (name != null) await cubit.updateUserName(name);
        },
      ),
      const SizedBox(height: AppSpacing.md),
      SettingsPremiumCardWidget(isPremium: isPremium, onUpgrade: () => context.push(AppRouter.kPaywallView)),
      const SizedBox(height: AppSpacing.lg),
      SettingsGroupCardWidget(
        title: context.tr('settings_group_preferences'),
        children: [
          SettingsTileWidget(
            icon: Icons.translate_rounded,
            title: context.tr('settings_language'),
            subtitle: SupportedLanguageModel.byCode(preferences.languageCode).nativeName,
            onTap: () async {
              final code = await showLanguagePickerSheet(context, currentCode: preferences.languageCode);
              if (code != null) await cubit.changeLanguage(code);
            },
          ),
          SettingsTileWidget(
            icon: Icons.notifications_rounded,
            title: context.tr('settings_notifications'),
            subtitle: context.tr('settings_notifications_subtitle'),
            trailing: Switch.adaptive(
              value: preferences.notificationsEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: cubit.setNotificationsEnabled,
            ),
          ),
          SettingsTileWidget(
            icon: Icons.hourglass_bottom_rounded,
            title: context.tr('settings_screen_time'),
            subtitle: context.tr(
              preferences.screenTimePermissionGranted ? 'settings_screen_time_on' : 'settings_screen_time_off',
            ),
            onTap: preferences.screenTimePermissionGranted || isRequestingPermission
                ? null
                : cubit.requestScreenTimePermission,
            trailing: isRequestingPermission
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    preferences.screenTimePermissionGranted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: preferences.screenTimePermissionGranted ? AppColors.success : AppColors.warning,
                  ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      SettingsGroupCardWidget(
        title: context.tr('settings_group_community'),
        children: [
          SettingsTileWidget(
            icon: Icons.rocket_launch_rounded,
            title: context.tr('feedback_screen_title'),
            subtitle: context.tr('settings_feedback_subtitle'),
            onTap: () => context.push(AppRouter.kFeedbackView),
          ),
          SettingsTileWidget(
            icon: Icons.star_rounded,
            title: context.tr('settings_rate'),
            // TODO(store): use in_app_review's requestReview().
            onTap: () => AppFunctions.showSnack(context, context.tr('coming_soon')),
          ),
          SettingsTileWidget(
            icon: Icons.ios_share_rounded,
            title: context.tr('settings_share'),
            // TODO(share): use share_plus with the store link.
            onTap: () => AppFunctions.showSnack(context, context.tr('coming_soon')),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      SettingsGroupCardWidget(
        title: context.tr('settings_group_account'),
        children: [
          SettingsTileWidget(
            icon: Icons.restore_rounded,
            title: context.tr('restore_purchases'),
            onTap: () => _restore(context),
          ),
          SettingsTileWidget(icon: Icons.privacy_tip_rounded, title: context.tr('privacy_policy'), onTap: () {}),
          SettingsTileWidget(icon: Icons.description_rounded, title: context.tr('terms_of_use'), onTap: () {}),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      SettingsGroupCardWidget(
        title: context.tr('settings_group_danger'),
        children: [
          SettingsTileWidget(
            icon: Icons.restart_alt_rounded,
            title: context.tr('settings_reset_title'),
            iconColor: AppColors.danger,
            iconBackground: AppColors.dangerSoft,
            titleColor: AppColors.danger,
            onTap: () => _reset(context),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        '${AppConstants.appName} v${AppConstants.appVersion}\n${context.tr('settings_footer')}',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(fontSize: 12),
      ),
    ];

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => current.failureKey != null && previous.failureKey != current.failureKey,
      listener: (context, state) => AppFunctions.showSnack(context, context.tr(state.failureKey!)),
      child: GlassScreenScaffold(
        palette: MeshPalette.calm,
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 130),
          children: sections.animate(interval: 35.ms).fadeIn(duration: 350.ms).slideY(begin: 0.05),
        ),
      ),
    );
  }
}

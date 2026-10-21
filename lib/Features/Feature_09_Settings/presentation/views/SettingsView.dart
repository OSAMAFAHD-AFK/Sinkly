import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/supported_language_model.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/app_toast_widget.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../../core/widgets/screen_title_header_widget.dart';
import '../../../Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import '../../data/data_sources/store_review_platform_data_source.dart';
import '../manager/settings_cubit.dart';
import 'widgets/settings_group_card_widget.dart';
import 'widgets/settings_profile_card_widget.dart';
import 'widgets/settings_sheets_widget.dart';
import 'widgets/settings_tile_widget.dart';
import 'widgets/share_invite_sheet_widget.dart';

/// Settings tab: profile, preferences, community, account.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _restore(BuildContext context) async {
    final subscription = context.read<SubscriptionCubit>();
    final restored = await subscription.restorePurchases();
    if (!context.mounted) return;
    if (restored) {
      AppFunctions.showSnack(context, context.tr('restore_success'), tone: AppToastTone.success);
    } else if (subscription.state.failureKey != null) {
      AppFunctions.showSnack(context, context.tr(subscription.state.failureKey!), tone: AppToastTone.error);
      subscription.clearFailure();
    }
  }

  /// The store's own subscription page: change plan or cancel in one tap.
  /// RevenueCat Customer Center; the store's subscriptions page when it
  /// isn't available (offline mock, not set up in the dashboard…).
  Future<void> _manageSubscription(BuildContext context) async {
    final cubit = context.read<SubscriptionCubit>();
    if (await cubit.openCustomerCenter()) return;
    final url = await cubit.manageSubscriptionUrl();
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  Future<void> _rate(BuildContext context) async {
    final outcome = await context.read<SettingsCubit>().rateApp();
    // Native sheet / store page handled it; otherwise explain (pre-launch).
    if (outcome == StoreReviewOutcome.unavailable && context.mounted) {
      AppFunctions.showSnack(context, context.tr('settings_rate_unavailable'));
    }
  }

  void _share(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    showShareInviteSheet(
      context,
      onShare: (message, subject, origin) => cubit.shareInvite(message: message, subject: subject, origin: origin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final preferences = context.select((SettingsCubit c) => c.state.preferences);
    final isRequestingPermission = context.select((SettingsCubit c) => c.state.isRequestingPermission);
    final isPremium = context.select((SubscriptionCubit c) => c.state.isPremium);

    final sections = <Widget>[
      ScreenTitleHeaderWidget(title: context.tr('settings_screen_title')),
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
          SettingsTileWidget(icon: Icons.star_rounded, title: context.tr('settings_rate'), onTap: () => _rate(context)),
          SettingsTileWidget(
            icon: Icons.ios_share_rounded,
            title: context.tr('settings_share'),
            onTap: () => _share(context),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      SettingsGroupCardWidget(
        title: context.tr('settings_group_account'),
        children: [
          SettingsTileWidget(
            icon: Icons.workspace_premium_rounded,
            title: context.tr('settings_manage_subscription'),
            subtitle: context.tr('settings_manage_subscription_subtitle'),
            onTap: () => _manageSubscription(context),
          ),
          SettingsTileWidget(
            icon: Icons.restore_rounded,
            title: context.tr('restore_purchases'),
            onTap: () => _restore(context),
          ),
          SettingsTileWidget(
            icon: Icons.help_outline_rounded,
            title: context.tr('settings_support'),
            onTap: () => _open(AppConstants.supportUrl),
          ),
          SettingsTileWidget(
            icon: Icons.privacy_tip_rounded,
            title: context.tr('privacy_policy'),
            onTap: () => _open(AppConstants.privacyUrl),
          ),
          SettingsTileWidget(
            icon: Icons.description_rounded,
            title: context.tr('terms_of_use'),
            onTap: () => _open(AppConstants.termsUrl),
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
      listener: (context, state) =>
          AppFunctions.showSnack(context, context.tr(state.failureKey!), tone: AppToastTone.error),
      child: GlassScreenScaffold(
        palette: MeshPalette.calm,
        safeAreaBottom: false,
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.md,
            AppSpacing.screenGutter,
            AppSpacing.mainTabScrollBottom(context),
          ),
          children: sections.animate(interval: 35.ms).fadeIn(duration: 350.ms).slideY(begin: 0.05),
        ),
      ),
    );
  }
}

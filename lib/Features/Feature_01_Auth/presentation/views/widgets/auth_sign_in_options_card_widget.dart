import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_secondary_button.dart';
import '../../../data/models/auth_user_model.dart';
import '../../manager/auth_cubit.dart';

/// Glass sheet with Apple / Google / Guest options and legal copy.
class AuthSignInOptionsCardWidget extends StatelessWidget {
  const AuthSignInOptionsCardWidget({super.key, required this.onProviderSelected});

  final ValueChanged<AuthProviderType> onProviderSelected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    Widget iconOrSpinner(AuthProviderType provider, Widget icon, {Color color = AppColors.ink}) =>
        state.isBusy && state.activeProvider == provider
        ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
        : icon;

    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      child: Column(
        children: [
          CustomSecondaryButton(
            isDark: true,
            label: context.tr('auth_continue_apple'),
            icon: iconOrSpinner(AuthProviderType.apple, Icon(FontAwesomeIcons.apple.data), color: Colors.white),
            onPressed: state.isBusy ? null : () => onProviderSelected(AuthProviderType.apple),
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomSecondaryButton(
            label: context.tr('auth_continue_google'),
            icon: iconOrSpinner(
              AuthProviderType.google,
              Icon(FontAwesomeIcons.google.data, color: const Color(0xFF4285F4)),
            ),
            onPressed: state.isBusy ? null : () => onProviderSelected(AuthProviderType.google),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: state.isBusy ? null : () => onProviderSelected(AuthProviderType.guest),
            child: state.isBusy && state.activeProvider == AuthProviderType.guest
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    context.tr('auth_continue_guest'),
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryInk),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('auth_legal'),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

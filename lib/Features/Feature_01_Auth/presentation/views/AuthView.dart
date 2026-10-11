import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/sinkly_logo_widget.dart';
import '../../data/models/auth_user_model.dart';
import '../manager/auth_cubit.dart';
import 'widgets/auth_sign_in_options_card_widget.dart';

/// "Save your plan" account screen shown after the paywall (and reachable
/// from Settings). Sign-in is optional: guests go straight to Home.
class AuthView extends StatelessWidget {
  const AuthView({super.key});

  Future<void> _onProviderSelected(BuildContext context, AuthProviderType provider) async {
    final success = await context.read<AuthCubit>().signIn(provider);
    if (!context.mounted) return;
    if (!success) {
      AppFunctions.showSnack(context, context.tr(context.read<AuthCubit>().state.failureKey ?? 'error_generic'));
      return;
    }
    AppFunctions.successHaptic();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.kHomeView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScreenScaffold(
      animateBackground: true,
      body: Stack(
        children: [
          const Positioned.fill(bottom: 320, child: FloatingSoapBubblesWidget()),
          // Scrollable + min-height keeps Spacers working while avoiding
          // overflow on small phones (iPhone SE).
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      const GlassIconOrbWidget(icon: Icons.cloud_done_rounded, size: 110)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                      const SizedBox(height: AppSpacing.md),
                      const SinklyLogoWidget(size: 30).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.tr('auth_title'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline,
                      ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('auth_subtitle'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.2),
                      const Spacer(flex: 3),
                      AuthSignInOptionsCardWidget(
                        onProviderSelected: (provider) => _onProviderSelected(context, provider),
                      ).animate(delay: 420.ms).fadeIn(duration: 450.ms).slideY(begin: 0.25, curve: Curves.easeOutCubic),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

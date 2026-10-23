import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../Feature_02_Onboarding/presentation/views/widgets/paywall_step_widget.dart';

/// Standalone paywall (opened from Settings, the Home upsell, etc.).
/// Reuses the exact onboarding paywall so pricing/A-B tests live in one place.
class PaywallView extends StatelessWidget {
  const PaywallView({super.key, this.strict = false});

  /// Shown at app open because the subscription has ended
  /// ([AppRouter.kSubscribeView]): like the onboarding paywall, "X" opens the
  /// exit offer and the only way on is subscribing or restoring → Home.
  final bool strict;

  @override
  Widget build(BuildContext context) {
    final userName = getIt<LocalStorageService>().plan.displayName;
    return GlassScreenScaffold(
      animateBackground: true,
      body: PaywallStepWidget(
        userName: userName,
        closeButtonDelay: strict ? const Duration(seconds: 3) : const Duration(milliseconds: 600),
        isDismissible: !strict,
        onFinished: (_) {
          if (strict) return context.go(AppRouter.kHomeView);
          if (context.canPop()) context.pop();
        },
      ),
    );
  }
}

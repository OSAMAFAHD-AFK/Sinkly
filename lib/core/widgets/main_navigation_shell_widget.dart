import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_localizations.dart';
import 'glass_bottom_navigation_bar.dart';

/// Hosts the 4 main tabs (Home · Plan · Progress · Settings). Each tab keeps
/// its own navigation stack & scroll position thanks to `StatefulShellRoute`.
class MainNavigationShellWidget extends StatelessWidget {
  const MainNavigationShellWidget({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: GlassBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        items: [
          GlassNavigationItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: context.tr('tab_home')),
          GlassNavigationItem(
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note_rounded,
            label: context.tr('tab_plan'),
          ),
          GlassNavigationItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: context.tr('tab_progress'),
          ),
          GlassNavigationItem(
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune_rounded,
            label: context.tr('tab_settings'),
          ),
        ],
      ),
    );
  }
}

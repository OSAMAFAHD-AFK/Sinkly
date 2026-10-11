import 'package:flutter/material.dart';

import '../utils/style.dart';
import 'animated_pressable_widget.dart';
import 'custom_card_container.dart';

class GlassNavigationItem {
  const GlassNavigationItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating frosted pill navigation bar (as in the Wlio reference), with a
/// sliding sky "bubble" behind the active tab.
class GlassBottomNavigationBar extends StatelessWidget {
  const GlassBottomNavigationBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<GlassNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
        child: CustomCardContainer(
          height: 70,
          padding: const EdgeInsets.all(7),
          borderRadius: AppRadii.pillAll,
          fillColor: AppColors.glassFillStrong,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: AppDurations.medium,
                    curve: Curves.easeOutBack,
                    start: itemWidth * currentIndex,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: AppRadii.pillAll,
                        boxShadow: AppShadows.primaryGlow(strength: 0.6),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: AnimatedPressableWidget(
                            onTap: () => onTap(index),
                            pressedScale: 0.9,
                            semanticLabel: items[index].label,
                            child: _NavigationItemContent(item: items[index], isActive: index == currentIndex),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavigationItemContent extends StatelessWidget {
  const _NavigationItemContent({required this.item, required this.isActive});

  final GlassNavigationItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.onPrimary : AppColors.inkMuted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: AppDurations.fast,
          child: Icon(isActive ? item.activeIcon : item.icon, key: ValueKey(isActive), color: color, size: 23),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(color: color, fontSize: 10.5, letterSpacing: 0.1),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/pulse_rings_widget.dart';

/// Screen 2 hero: a waving hand that turns into the user's own avatar
/// (first letter of the typed name) with a springy pop and sparkles —
/// instant, personal feedback while typing.
class NameAvatarOrbWidget extends StatelessWidget {
  const NameAvatarOrbWidget({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hasName = name.trim().isNotEmpty;
    final initial = AppFunctions.initialOf(name);

    return PulseRingsWidget(
      size: 190,
      color: hasName ? AppColors.primary : AppColors.meshLavender,
      child: SizedBox.square(
        dimension: 120,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasName
                    ? AppGradients.primaryButton
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFE9E7FF)],
                      ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: (hasName ? AppColors.primary : AppColors.meshLavender).withValues(alpha: 0.55),
                    blurRadius: 40,
                    spreadRadius: -4,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: Curves.elasticOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: hasName
                    ? Text(
                        initial,
                        key: ValueKey(initial),
                        style: AppTextStyles.display.copyWith(fontSize: 54, color: AppColors.onPrimary),
                      )
                    : const Text('👋', key: ValueKey('wave'), style: TextStyle(fontSize: 52))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(begin: -0.08, end: 0.1, alignment: Alignment.bottomRight, duration: 650.ms),
              ),
            ),
            // Sparkles around the avatar appear once there's a name.
            for (final (index, spot) in const [
              Alignment(-1.1, -0.9),
              Alignment(1.15, -0.6),
              Alignment(1.0, 0.95),
            ].indexed)
              Align(
                alignment: spot,
                child: AnimatedOpacity(
                  opacity: hasName ? 1 : 0,
                  duration: AppDurations.slow,
                  child:
                      Icon(
                            Icons.auto_awesome_rounded,
                            size: 16.0 + index * 4,
                            color: index == 1 ? const Color(0xFFFFC857) : AppColors.primary,
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true), delay: (index * 250).ms)
                          .scaleXY(begin: 0.6, end: 1.2, duration: 800.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

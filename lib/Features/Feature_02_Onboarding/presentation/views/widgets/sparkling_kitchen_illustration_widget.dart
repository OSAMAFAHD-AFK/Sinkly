import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';

/// Screen 4 illustration: a sparkling clean-sink orb with twinkling stars and
/// floating "feeling" chips (Clear mind · No guilt · Fresh start).
class SparklingKitchenIllustrationWidget extends StatelessWidget {
  const SparklingKitchenIllustrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const GlassIconOrbWidget(emoji: '🚰', size: 112, glowColor: AppColors.primary),
          ..._sparkles(),
          _FeelingChip(
            label: context.tr('reality_chip_clear_mind'),
            alignment: const AlignmentDirectional(-1, -0.75),
            delayMs: 200,
          ),
          _FeelingChip(
            label: context.tr('reality_chip_no_guilt'),
            alignment: const AlignmentDirectional(1, -0.2),
            delayMs: 400,
          ),
          _FeelingChip(
            label: context.tr('reality_chip_fresh_start'),
            alignment: const AlignmentDirectional(-0.85, 0.85),
            delayMs: 600,
          ),
        ],
      ),
    );
  }

  List<Widget> _sparkles() {
    const positions = [
      Alignment(-0.35, -0.9),
      Alignment(0.45, -0.75),
      Alignment(0.6, 0.55),
      Alignment(-0.15, 0.95),
      Alignment(0.95, -0.95),
    ];
    return [
      for (var i = 0; i < positions.length; i++)
        Align(
          alignment: positions[i],
          child:
              Icon(
                    Icons.auto_awesome_rounded,
                    size: 14.0 + (i % 3) * 6,
                    color: i.isEven ? AppColors.primary : const Color(0xFFFFC36B),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 220).ms)
                  .scaleXY(begin: 0.5, end: 1.1, duration: 900.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 500.ms),
        ),
    ];
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({required this.label, required this.alignment, required this.delayMs});

  final String label;
  final AlignmentDirectional alignment;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child:
          Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: AppShadows.floating,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
              )
              // Inner: endless gentle float. Outer: one-shot entrance.
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -6, duration: 2000.ms, curve: Curves.easeInOut)
              .animate(delay: delayMs.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.4, curve: Curves.easeOutBack),
    );
  }
}

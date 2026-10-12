import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_mark_painter.dart';

/// Splash brand moment, told as the app's promise in ~2.4 s:
/// the Sink-Lock tile pops in → a drop falls from the faucet-shackle → the
/// basin fills → the lock springs slightly open with a sparkle. A soft halo
/// breathes behind it, then the wordmark and tagline glide up.
class SplashAnimatedLogoWidget extends StatefulWidget {
  const SplashAnimatedLogoWidget({super.key});

  /// Total time until the whole lockup is on screen (used by the splash gate).
  static const Duration totalDuration = Duration(milliseconds: 2900);

  @override
  State<SplashAnimatedLogoWidget> createState() => _SplashAnimatedLogoWidgetState();
}

class _SplashAnimatedLogoWidgetState extends State<SplashAnimatedLogoWidget> with TickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 2400);

  late final AnimationController _intro = AnimationController(vsync: this, duration: _introDuration)..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _idle.repeat();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const markSize = 136.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Breathing sky halo.
              Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.45), AppColors.primary.withValues(alpha: 0)],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.85, end: 1.08, duration: 1800.ms, curve: Curves.easeInOut),
              // Ripple that leaves the tile the moment the lock opens.
              Container(
                    width: markSize,
                    height: markSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(markSize * 0.23),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.7), width: 2),
                    ),
                  )
                  // Hidden until the lock opens, then expands and fades away.
                  .animate(delay: 1450.ms)
                  .fade(begin: 0, end: 1, duration: 60.ms)
                  .then()
                  .scaleXY(begin: 1, end: 1.45, duration: 900.ms, curve: Curves.easeOut)
                  .fadeOut(duration: 900.ms),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(markSize * 0.23),
                  boxShadow: [
                    BoxShadow(
                      color: SinklyLogoMarkPainter.skyBottom.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: SizedBox.square(
                  dimension: markSize,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _AnimatedMarkPainter(intro: _intro, idle: _idle),
                    ),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 250.ms),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sinkly',
          style: AppTextStyles.display.copyWith(fontSize: 42, letterSpacing: -1.2),
        ).animate(delay: 1550.ms).fadeIn(duration: 500.ms).slideY(begin: 0.35, curve: Curves.easeOutBack),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(context.tr('splash_tagline'), style: AppTextStyles.body, textAlign: TextAlign.center),
        ).animate(delay: 1900.ms).fadeIn(duration: 500.ms).slideY(begin: 0.4, curve: Curves.easeOutCubic),
      ],
    );
  }
}

/// Repaints only the mark from the two controllers (no widget rebuilds).
class _AnimatedMarkPainter extends CustomPainter {
  _AnimatedMarkPainter({required this.intro, required this.idle}) : super(repaint: Listenable.merge([intro, idle]));

  final Animation<double> intro;
  final AnimationController idle;

  @override
  void paint(Canvas canvas, Size size) {
    final idleSeconds = (idle.value * idle.duration!.inMilliseconds) / 1000;
    SinklyLogoMarkPainter(intro: intro.value, idle: idleSeconds).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _AnimatedMarkPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';

/// The glowing "slot" the OS permission popup lands in.
///
/// iOS draws its Screen Time alert in the middle of the screen, ABOVE every
/// Flutter pixel, so Sinkly never paints a fake dialog: this frame sits
/// exactly where Apple's real card appears and simply outlines it (the same
/// trick Opal and Freedom use). Before/after the popup the frame shows
/// [child] (a soft placeholder, or the Android Settings guide), and a
/// success state once access is granted.
class SystemPromptFrameWidget extends StatefulWidget {
  const SystemPromptFrameWidget({super.key, required this.child, this.isGranted = false});

  final Widget child;
  final bool isGranted;

  static const double radius = 38;

  @override
  State<SystemPromptFrameWidget> createState() => _SystemPromptFrameWidgetState();
}

class _SystemPromptFrameWidgetState extends State<SystemPromptFrameWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowFramePainter(animation: _controller, isGranted: widget.isGranted),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AnimatedSwitcher(
          duration: AppDurations.slow,
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(animation), child: child),
          ),
          child: widget.isGranted
              ? const _GrantedContent(key: ValueKey('granted'))
              : KeyedSubtree(key: const ValueKey('waiting'), child: widget.child),
        ),
      ),
    );
  }
}

/// Rotating aurora border + breathing outer glow.
class _GlowFramePainter extends CustomPainter {
  _GlowFramePainter({required this.animation, required this.isGranted}) : super(repaint: animation);

  final Animation<double> animation;
  final bool isGranted;

  static const _waitingColors = [
    AppColors.primary,
    Color(0xFFB9A8FF),
    Color(0xFF8FE3C8),
    AppColors.primaryDeep,
    AppColors.primary,
  ];
  static const _grantedColors = [
    Color(0xFF7FE0BC),
    AppColors.success,
    Color(0xFFB5F0DA),
    AppColors.success,
    Color(0xFF7FE0BC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(SystemPromptFrameWidget.radius));
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2);
    final glowColor = isGranted ? AppColors.success : AppColors.primary;

    // Outer halo.
    canvas.drawRRect(
      rrect.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + 6 * breathe
        ..color = glowColor.withValues(alpha: 0.16 + 0.12 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Frosted slot: lighter than the page so the popup reads as "placed in".
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.18)],
        ).createShader(rect),
    );

    // Aurora border, slowly orbiting.
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = SweepGradient(
          colors: isGranted ? _grantedColors : _waitingColors,
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(rect),
    );

    // Inner light edge for the glass feel.
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_GlowFramePainter oldDelegate) => oldDelegate.isGranted != isGranted;
}

class _GrantedContent extends StatelessWidget {
  const _GrantedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppGradients.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
            ).animate().scale(begin: const Offset(0.4, 0.4), duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr('permission_connected'), textAlign: TextAlign.center, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context.tr('permission_connected_body'),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS placeholder: a faint silhouette of the system alert, so the frame
/// never looks empty before Apple's card appears (or after "Don't Allow").
/// The "allow" button (start side, like Apple's) softly pulses.
class GhostSystemDialogWidget extends StatelessWidget {
  const GhostSystemDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, {double height = 10}) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.07), borderRadius: AppRadii.pillAll),
      ),
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md + 2, AppSpacing.md, AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            bar(0.78, height: 12),
            const SizedBox(height: 7),
            bar(0.5, height: 12),
            const SizedBox(height: AppSpacing.sm),
            bar(0.92, height: 8),
            const SizedBox(height: 6),
            bar(0.64, height: 8),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child:
                      Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: AppRadii.pillAll,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.7), width: 1.4),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .custom(
                            duration: 1100.ms,
                            curve: Curves.easeInOut,
                            builder: (context, value, child) => DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: AppRadii.pillAll,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.18 + 0.32 * value),
                                    blurRadius: 8 + 10 * value,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2200.ms, delay: 600.ms, color: Colors.white),
    );
  }
}

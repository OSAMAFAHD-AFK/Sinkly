import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import 'feedback_aurora_backdrop_widget.dart';
import 'feedback_idea_journey_widget.dart';

/// "Sinkly Lab" hero: a midnight-sky card with drifting aurora light, a
/// gradient-lit headline and the journey every idea takes to a release.
/// Deliberately the one dark surface of the screen, so it reads as premium.
class FeedbackHeroCardWidget extends StatelessWidget {
  const FeedbackHeroCardWidget({super.key});

  static const LinearGradient _night = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E2340), Color(0xFF173A66), Color(0xFF2B5F96)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.largeAll,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173A66).withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.largeAll,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _night),
          position: DecorationPosition.background,
          child: Stack(
            children: [
              const Positioned.fill(child: FeedbackAuroraBackdropWidget()),
              // Glass sheen + hairline rim light on top of the aurora.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.largeAll,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg - 2, AppSpacing.lg - 4, AppSpacing.lg - 2, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LabStatusRow(),
                    const SizedBox(height: AppSpacing.md),
                    const _GradientHeadline(),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.tr('feedback_hero_description'),
                      style: AppTextStyles.body.copyWith(fontSize: 14, color: Colors.white.withValues(alpha: 0.74)),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    const FeedbackIdeaJourneyWidget(),
                  ].animate(interval: 70.ms, delay: 120.ms).fadeIn(duration: 420.ms).slideY(begin: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "✦ SINKLY LAB" badge + a live "open for ideas" status.
class _LabStatusRow extends StatelessWidget {
  const _LabStatusRow();

  @override
  Widget build(BuildContext context) {
    final spacing = context.isRtl ? 0.0 : 1.4; // tracking breaks Arabic joins
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppRadii.pillAll,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFFFE08A))
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(begin: 0, end: 1, duration: 9.seconds),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('feedback_lab_badge'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: Colors.white, letterSpacing: spacing, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6EF0B5),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF6EF0B5).withValues(alpha: 0.8), blurRadius: 8)],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.7, end: 1.15, duration: 1100.ms, curve: Curves.easeInOut),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('feedback_lab_status'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// White lead-in + an aurora-gradient highlight on the promise itself.
class _GradientHeadline extends StatelessWidget {
  const _GradientHeadline();

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.title.copyWith(fontSize: 23, height: 1.3, color: Colors.white, fontWeight: FontWeight.w800);
    return LayoutBuilder(
      builder: (context, constraints) {
        final highlight = Paint()
          ..shader = LinearGradient(
            colors: const [Color(0xFFA6E1FF), Color(0xFFD9CCFF), Color(0xFFFFC2D6)],
            begin: context.isRtl ? Alignment.centerRight : Alignment.centerLeft,
            end: context.isRtl ? Alignment.centerLeft : Alignment.centerRight,
          ).createShader(Rect.fromLTWH(0, 0, constraints.maxWidth, 30));
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${context.tr('feedback_hero_title_lead')} '),
              TextSpan(
                text: context.tr('feedback_hero_title_highlight'),
                style: TextStyle(foreground: highlight),
              ),
            ],
          ),
          style: base,
        );
      },
    );
  }
}

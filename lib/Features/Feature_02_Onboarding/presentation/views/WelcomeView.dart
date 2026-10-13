import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/adaptive_scene_box_widget.dart';
import '../../../../core/widgets/confetti_burst_widget.dart';
import '../../../../core/widgets/custom_card_container.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import 'widgets/heroine_character_painter.dart';
import 'widgets/heroine_character_widget.dart';
import 'widgets/heroine_speech_bubble_widget.dart';
import 'widgets/onboarding_step_header_widget.dart';
import 'widgets/rising_emoji_particles_widget.dart';

/// Shown right after the subscription on the paywall, before Home.
///
/// The heroine the user followed through the whole onboarding celebrates
/// with them (confetti, jump for joy) → hugs a heart, "so proud of you" →
/// introduces Mom Points, the reward for every clean sink → "Let's go!".
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  /// How long she jumps for joy before the calmer "proud of you" moment.
  static const Duration partyLength = Duration(milliseconds: 2400);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final List<Timer> _timers = [];
  bool _proud = false;
  bool _showPoints = false;

  @override
  void initState() {
    super.initState();
    AppFunctions.successHaptic();
    _timers
      ..add(Timer(const Duration(milliseconds: 1100), () => _update(() => _showPoints = true)))
      ..add(Timer(WelcomeView.partyLength, () => _update(() => _proud = true)));
  }

  void _update(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _start() => context.go(AppRouter.kHomeView);

  @override
  Widget build(BuildContext context) {
    final name = getIt<LocalStorageService>().plan.displayName.trim();

    return GlassScreenScaffold(
      animateBackground: true,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _start();
        },
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingSoapBubblesWidget(bubbleCount: 8, maxBubbleSize: 30)),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenGutter,
                      AppSpacing.lg,
                      AppSpacing.screenGutter,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                              child: AdaptiveSceneBoxWidget(
                                maxHeightFraction: 0.34,
                                child: _WelcomeScene(proud: _proud, name: name),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 450.ms)
                            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                        const SizedBox(height: AppSpacing.md),
                        OnboardingStepHeaderWidget(
                              title: name.isEmpty
                                  ? context.tr('welcome_title_generic')
                                  : context.tr('welcome_title', {'name': '\u2068$name\u2069'}),
                              highlight: name,
                              description: context.tr('welcome_subtitle'),
                            )
                            .animate(delay: 250.ms)
                            .fadeIn(duration: 450.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                        const SizedBox(height: AppSpacing.lg),
                        _MomPointsCard(counting: _showPoints)
                            .animate(delay: 650.ms)
                            .fadeIn(duration: 450.ms)
                            .slideY(begin: 0.15, curve: Curves.easeOutBack),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.xs,
                    AppSpacing.screenGutter,
                    AppSpacing.md,
                  ),
                  child: CustomPrimaryButton(
                    label: context.tr('welcome_cta'),
                    showShimmer: true,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _start,
                  ).animate(delay: 900.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic),
                ),
              ],
            ),
            // Celebration burst on arrival.
            const Positioned.fill(child: IgnorePointer(child: ConfettiBurstWidget(particleCount: 110))),
          ],
        ),
      ),
    );
  }
}

/// The heroine celebrating, with her bubble right next to her.
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({required this.proud, required this.name});

  final bool proud;
  final String name;

  static const double _heroineWidth = 168;
  static const double _heroineStart = 18;

  @override
  Widget build(BuildContext context) {
    final heroineHeight = HeroineCharacterWidget.heightFor(_heroineWidth);
    final (pose, motion, prop) = proud
        ? (HeroinePose.cherishJoy, HeroineMotion.cherish, HeroineProp.heart)
        : (HeroinePose.joyJump, HeroineMotion.jumpJoy, HeroineProp.none);
    final bubble = proud
        ? context.tr('welcome_bubble_proud')
        : name.isEmpty
        ? context.tr('welcome_bubble_party_generic')
        : context.tr('welcome_bubble_party', {'name': '\u2068$name\u2069'});

    return SizedBox(
      width: 340,
      height: heroineHeight + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Warm halo behind her.
          PositionedDirectional(
            start: _heroineStart - 40,
            top: 0,
            width: _heroineWidth + 80,
            height: heroineHeight + 24,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0xCCFFE1EC), Color(0x00FFE1EC)])),
              ),
            ),
          ),
          PositionedDirectional(
            start: _heroineStart,
            bottom: 0,
            child: HeroineCharacterWidget(width: _heroineWidth, pose: pose, motion: motion, prop: prop),
          ),
          // Hearts & sparkles rising from her hands.
          const PositionedDirectional(
            start: _heroineStart + _heroineWidth / 2 - 30,
            top: 26,
            child: RisingEmojiParticlesWidget(
              emojis: ['💖', '✨', '💙', '✨', '💖'],
              rise: 80,
              spread: 40,
              fontSize: 17,
              interval: Duration(milliseconds: 300),
              lifetime: Duration(milliseconds: 1700),
            ),
          ),
          // Bubble right next to her, a little above her head.
          PositionedDirectional(
            start: _heroineStart + _heroineWidth - 22,
            end: 0,
            top: 0,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: HeroineSpeechBubbleSwitcherWidget(text: bubble),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Mom Points": the reward for every clean sink, with a counting badge.
class _MomPointsCard extends StatelessWidget {
  const _MomPointsCard({required this.counting});

  final bool counting;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFC2D6), Color(0xFFFF7FA5)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7FA5).withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text('💖', style: TextStyle(fontSize: 26)),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.08, duration: 900.ms, curve: Curves.easeInOut),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('welcome_points_title'), style: AppTextStyles.titleSmall.copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                Text(context.tr('welcome_points_body'), style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: counting ? AppConstants.momPointsPerClean : 0),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '+$value',
                  // Keep "+10" (not "10+") inside Arabic layouts.
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.title.copyWith(color: const Color(0xFFE0457B), fontWeight: FontWeight.w800),
                ),
              ),
              Text(context.tr('welcome_points_per_clean'), style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/adaptive_scene_box_widget.dart';
import '../../../../core/widgets/confetti_burst_widget.dart';
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
/// "Let's go!". Everything sits centered on the screen.
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

  @override
  void initState() {
    super.initState();
    AppFunctions.successHaptic();
    _timers.add(Timer(WelcomeView.partyLength, () => _update(() => _proud = true)));
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
                  // Centered in the free space above the button; scrolls only
                  // on very short phones / huge text.
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenGutter,
                            AppSpacing.md,
                            AppSpacing.screenGutter,
                            AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                    child: AdaptiveSceneBoxWidget(
                                      maxDesignWidth: _WelcomeScene.width,
                                      maxHeightFraction: 0.42,
                                      child: _WelcomeScene(proud: _proud, name: name),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 450.ms)
                                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                              const SizedBox(height: AppSpacing.lg),
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
                            ],
                          ),
                        ),
                      ),
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

/// The heroine celebrating, centered, with her bubble up beside her head.
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({required this.proud, required this.name});

  final bool proud;
  final String name;

  static const double width = 360;
  static const double _heroineWidth = 176;
  static const double _heroineStart = (width - _heroineWidth) / 2;
  static const double _bubbleStart = _heroineStart + _heroineWidth * 0.66;

  /// Room above her head for the bubble.
  static const double _topRoom = 44;

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
      width: width,
      height: heroineHeight + _topRoom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Warm halo behind her.
          PositionedDirectional(
            start: _heroineStart - 40,
            top: _topRoom / 2,
            width: _heroineWidth + 80,
            height: heroineHeight,
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
            top: _topRoom + 26,
            child: RisingEmojiParticlesWidget(
              emojis: ['💖', '✨', '💙', '✨', '💖'],
              rise: 80,
              spread: 40,
              fontSize: 17,
              interval: Duration(milliseconds: 300),
              lifetime: Duration(milliseconds: 1700),
            ),
          ),
          // Bubble up beside her head, its tail pointing back at her.
          PositionedDirectional(
            start: _bubbleStart,
            end: 0,
            top: 0,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: HeroineSpeechBubbleSwitcherWidget(text: bubble, maxWidth: width - _bubbleStart),
            ),
          ),
        ],
      ),
    );
  }
}

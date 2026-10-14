import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/dev_shortcut_button_widget.dart';
import '../../../../core/widgets/floating_soap_bubbles_widget.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../manager/onboarding_cubit.dart';
import 'widgets/dish_pileup_diagnosis_quiz_step_widget.dart';
import 'widgets/dishwashing_struggle_empathy_step_widget.dart';
import 'widgets/distracting_apps_selection_step_widget.dart';
import 'widgets/emotional_pain_point_step_widget.dart';
import 'widgets/language_selection_step_widget.dart';
import 'widgets/meal_schedule_setup_step_widget.dart';
import 'widgets/name_input_step_widget.dart';
import 'widgets/onboarding_progress_bar_widget.dart';
import 'widgets/paywall_step_widget.dart';
import 'widgets/personal_commitment_step_widget.dart';
import 'widgets/personalized_plan_summary_step_widget.dart';
import 'widgets/reality_check_step_widget.dart';
import 'widgets/screen_time_permission_step_widget.dart';
import 'widgets/sinkly_solution_explainer_step_widget.dart';
import 'widgets/time_loss_friction_analysis_step_widget.dart';
import 'widgets/trial_reminder_assurance_step_widget.dart';

/// The 15-screen onboarding funnel in a single, cubit-driven [PageView].
///
/// * Swipe is disabled — progress only moves through CTAs (keeps answers valid).
/// * Pages are built lazily by [PageView.builder]; only the visible step lives.
/// * System back / swipe-back goes to the previous step instead of exiting.
///
/// Adapty Onboarding Builder: when `AppConstants.useAdaptyOnboardingBuilder`
/// is enabled, the router can present the remote onboarding instead of this
/// view; answers would then be mapped into the same OnboardingUserPreferencesModel.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController = PageController(
    initialPage: context.read<OnboardingCubit>().state.stepIndex,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage(OnboardingState state) {
    if (!_pageController.hasClients) return;
    FocusManager.instance.primaryFocus?.unfocus();
    AppFunctions.selectionHaptic();
    _pageController.animateToPage(state.stepIndex, duration: AppDurations.page, curve: Curves.easeInOutCubic);
  }

  Future<void> _finishOnboarding(bool purchased) async {
    final completed = await context.read<OnboardingCubit>().completeOnboarding();
    if (!mounted || !completed) return;
    // Strict paywall: we only get here after subscribing → celebrate, then Home.
    context.go(AppRouter.kWelcomeView);
  }

  // TODO(dev): remove with AppConstants.showDevOnboardingSkip before release.
  Future<void> _devSkipToWelcome() async {
    AppFunctions.lightHaptic();
    final completed = await context.read<OnboardingCubit>().devSkipToWelcome();
    if (mounted && completed) context.go(AppRouter.kWelcomeView);
  }

  Widget _buildStep(OnboardingStep step) => switch (step) {
    OnboardingStep.languageSelection => const LanguageSelectionStepWidget(),
    OnboardingStep.nameInput => const NameInputStepWidget(),
    OnboardingStep.emotionalPainPoint => const EmotionalPainPointStepWidget(),
    OnboardingStep.realityCheck => const RealityCheckStepWidget(),
    OnboardingStep.dishPileupDiagnosisQuiz => const DishPileupDiagnosisQuizStepWidget(),
    OnboardingStep.dishwashingStruggleEmpathy => const DishwashingStruggleEmpathyStepWidget(),
    OnboardingStep.timeLossFrictionAnalysis => const TimeLossFrictionAnalysisStepWidget(),
    OnboardingStep.mealScheduleSetup => const MealScheduleSetupStepWidget(),
    OnboardingStep.distractingAppsSelection => const DistractingAppsSelectionStepWidget(),
    OnboardingStep.screenTimePermission => const ScreenTimePermissionStepWidget(),
    OnboardingStep.sinklySolutionExplainer => const SinklySolutionExplainerStepWidget(),
    OnboardingStep.personalCommitment => const PersonalCommitmentStepWidget(),
    OnboardingStep.personalizedPlanSummary => const PersonalizedPlanSummaryStepWidget(),
    OnboardingStep.trialReminderAssurance => const TrialReminderAssuranceStepWidget(),
    OnboardingStep.paywall => PaywallStepWidget(
      userName: context.read<OnboardingCubit>().state.preferences.trimmedName,
      onFinished: _finishOnboarding,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final currentStep = context.select((OnboardingCubit c) => c.state.currentStep);

    return PopScope(
      canPop: currentStep.isFirst,
      onPopInvokedWithResult: (didPop, _) {
        // No going back once the commitment is sealed (screens without chrome).
        if (!didPop && currentStep.showsChrome) context.read<OnboardingCubit>().previousStep();
      },
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listenWhen: (previous, current) => previous.currentStep != current.currentStep,
        listener: (context, state) => _syncPage(state),
        child: GlassScreenScaffold(
          animateBackground: true,
          body: Stack(
            children: [
              // Ambient soap bubbles drift behind every step (frosted by the glass).
              const Positioned.fill(child: FloatingSoapBubblesWidget(bubbleCount: 7, maxBubbleSize: 30)),
              Column(
                children: [
                  AnimatedSize(
                    duration: AppDurations.medium,
                    child: currentStep.showsChrome
                        ? _OnboardingTopBar(step: currentStep)
                        : const SizedBox(width: double.infinity),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: OnboardingStep.values.length,
                      itemBuilder: (context, index) => _ParallaxPage(
                        controller: _pageController,
                        index: index,
                        child: _buildStep(OnboardingStep.values[index]),
                      ),
                    ),
                  ),
                ],
              ),
              // TODO(dev): DEVELOPMENT ONLY — jump straight to Welcome. Sits in
              // the top bar's back-button slot (empty on the first screen) and
              // never reaches the centred progress track.
              if (AppConstants.showDevOnboardingSkip && currentStep.isFirst)
                PositionedDirectional(
                  start: AppSpacing.screenGutter - 6,
                  top: AppSpacing.xs,
                  height: 46,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (MediaQuery.sizeOf(context).width - _OnboardingTopBar.trackWidth) / 2 -
                            AppSpacing.screenGutter,
                      ),
                      child: DevShortcutButtonWidget(
                        label: context.tr('onboarding_dev_skip'),
                        icon: Icons.fast_forward_rounded,
                        onPressed: _devSkipToWelcome,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slides + fades + gently scales pages as they swipe in/out, so the funnel
/// feels like one continuous motion instead of hard cuts.
class _ParallaxPage extends StatelessWidget {
  const _ParallaxPage({required this.controller, required this.index, required this.child});

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        var delta = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? index.toDouble()) - index;
        }
        final distance = delta.abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: (1 - distance * 1.4).clamp(0.0, 1.0),
          child: Transform.translate(
            // Content lags slightly behind the page → depth.
            offset: Offset(MediaQuery.sizeOf(context).width * 0.18 * delta * (context.isRtl ? -1 : 1), 0),
            child: Transform.scale(scale: 1 - 0.06 * distance, child: child),
          ),
        );
      },
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.step});

  final OnboardingStep step;

  static const double trackWidth = 148;

  @override
  Widget build(BuildContext context) {
    final progress = context.select((OnboardingCubit c) => c.state.progress);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter - 6, AppSpacing.xs, AppSpacing.screenGutter, 0),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedOpacity(
                opacity: step.isFirst ? 0 : 1,
                duration: AppDurations.medium,
                child: IgnorePointer(
                  ignoring: step.isFirst,
                  child: GlassIconButton.back(
                    context: context,
                    onPressed: context.read<OnboardingCubit>().previousStep,
                  ),
                ),
              ),
            ),
            // Short centered track (reference layout); keep Sinkly bar styling.
            SizedBox(width: trackWidth, child: OnboardingProgressBarWidget(progress: progress)),
          ],
        ),
      ),
    );
  }
}

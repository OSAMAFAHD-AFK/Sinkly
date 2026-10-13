import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../data/models/screen_time_access_model.dart';
import '../../manager/onboarding_cubit.dart';
import 'android_settings_toggle_guide_widget.dart';
import 'onboarding_step_header_widget.dart';
import 'permission_pointer_arrow_widget.dart';
import 'sinkly_permission_card_widget.dart';
import 'system_prompt_frame_widget.dart';

/// Screen 9 — Screen Time permission, the real one.
///
/// * iOS: shortly after the screen settles, Apple's own Screen Time alert
///   is requested. It appears in the middle of the screen, so the glowing
///   [SystemPromptFrameWidget] is pinned to the exact screen centre and the
///   arrow points at Apple's "Continue" button.
/// * Android: no system popup exists for app blocking, so the same frame
///   holds Sinkly's own card. "Continue" flips it into a replica of the
///   Settings switch, Settings opens by itself a moment later, and the step
///   completes on its own when the user comes back with it switched on.
class ScreenTimePermissionStepWidget extends StatefulWidget {
  const ScreenTimePermissionStepWidget({super.key});

  /// Time for the page transition + entrance animations to finish, so the
  /// system alert lands on a settled frame.
  static const Duration autoPromptDelay = Duration(milliseconds: 1200);

  /// Android: how long the Settings replica is shown before Settings opens.
  static const Duration openSettingsDelay = Duration(milliseconds: 1700);

  @override
  State<ScreenTimePermissionStepWidget> createState() => _ScreenTimePermissionStepWidgetState();
}

class _ScreenTimePermissionStepWidgetState extends State<ScreenTimePermissionStepWidget> {
  late final OnboardingCubit _cubit = context.read<OnboardingCubit>();
  final GlobalKey _layoutKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  Timer? _autoPromptTimer;
  Timer? _remeasureTimer;
  Timer? _openSettingsTimer;
  bool _autoPrompted = false;

  /// Android: the user tapped "Continue" on Sinkly's card.
  bool _androidCardAccepted = false;
  bool _openingSettings = false;

  /// Global y of this step's top edge (to centre the frame on the SCREEN).
  double? _globalTop;

  bool get _isCurrentStep => _cubit.state.currentStep == OnboardingStep.screenTimePermission;

  @override
  void initState() {
    super.initState();
    // Back from Settings / the system alert → re-read the real status.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_isCurrentStep) _cubit.refreshScreenTimeAccess();
      },
    );
    _cubit.refreshScreenTimeAccess().then((_) => _scheduleAutoPrompt());
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    // Re-measure once the page transition (which scales the page) is over.
    _remeasureTimer = Timer(AppDurations.page + const Duration(milliseconds: 120), _measure);
  }

  @override
  void dispose() {
    _autoPromptTimer?.cancel();
    _remeasureTimer?.cancel();
    _openSettingsTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final box = _layoutKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (_globalTop == null || (top - _globalTop!).abs() > 0.5) setState(() => _globalTop = top);
  }

  /// iOS only: Apple's alert is a popup, so it is shown right away — the
  /// user just taps "Continue". (On Android the user starts from Sinkly's
  /// card, since the next thing is leaving the app for Settings.)
  void _scheduleAutoPrompt() {
    final access = _cubit.state.screenTimeAccess;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (_autoPrompted || !isIos || access == null || access.nextMissing?.isSystemPrompt != true) return;
    _autoPrompted = true;
    _autoPromptTimer = Timer(ScreenTimePermissionStepWidget.autoPromptDelay, () {
      if (!mounted || !_isCurrentStep) return;
      if (_cubit.state.permissionStatus == OnboardingRequestStatus.idle) _cubit.requestScreenTimePermission();
    });
  }

  /// Android: card → flip to the Settings replica → Settings opens itself.
  void _acceptAndroidCard() {
    if (_androidCardAccepted) return;
    setState(() {
      _androidCardAccepted = true;
      _openingSettings = true;
    });
    _openSettingsTimer = Timer(ScreenTimePermissionStepWidget.openSettingsDelay, () {
      if (!mounted) return;
      setState(() => _openingSettings = false);
      if (_isCurrentStep) _cubit.requestScreenTimePermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = context.select((OnboardingCubit c) => c.state.screenTimeAccess);
    final status = context.select((OnboardingCubit c) => c.state.permissionStatus);
    final failureKey = context.select((OnboardingCubit c) => c.state.failureKey);
    final grantedEarlier = context.select((OnboardingCubit c) => c.state.preferences.screenTimePermissionGranted);

    final isCurrent = context.select((OnboardingCubit c) => c.state.currentStep == OnboardingStep.screenTimePermission);

    final isGranted = status == OnboardingRequestStatus.success || (access?.isGranted ?? grantedEarlier);
    // Leaving the step resets the status: keep the "enabled ✓" label while
    // the page slides away instead of flashing "Continue".
    final justGranted = status == OnboardingRequestStatus.success || (isGranted && !isCurrent);
    final usesSystemPrompt = access?.usesSystemPrompt ?? defaultTargetPlatform == TargetPlatform.iOS;
    final isRequesting = status == OnboardingRequestStatus.inProgress || _openingSettings;
    // Android intro: Sinkly's card (until "Continue", or a switch is already on).
    final showAndroidCard =
        !usesSystemPrompt && !isGranted && !_androidCardAccepted && (access?.grantedCount ?? 0) == 0;
    final showArrow = !isGranted && (usesSystemPrompt || showAndroidCard);

    final String ctaLabel;
    final VoidCallback? onCtaPressed;
    if (justGranted) {
      ctaLabel = context.tr('permission_granted');
      onCtaPressed = null;
    } else if (isGranted) {
      ctaLabel = context.tr('continue');
      onCtaPressed = _cubit.nextStep;
    } else {
      ctaLabel = context.tr(usesSystemPrompt ? 'permission_cta_ios' : 'permission_cta_android');
      onCtaPressed = _cubit.requestScreenTimePermission;
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          (previous.permissionStatus != current.permissionStatus &&
              current.permissionStatus == OnboardingRequestStatus.success) ||
          (previous.screenTimeAccess != null &&
              (current.screenTimeAccess?.grantedCount ?? 0) > previous.screenTimeAccess!.grantedCount),
      listener: (context, state) async {
        if (state.permissionStatus != OnboardingRequestStatus.success) {
          return AppFunctions.lightHaptic(); // Android: first switch done.
        }
        AppFunctions.successHaptic();
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (context.mounted && _isCurrentStep) _cubit.nextStep();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = Size(
            math.min(constraints.maxWidth - 2 * AppSpacing.md, 340),
            (usesSystemPrompt ? 150 : 190) + 100 * textScale,
          );
          final globalTop = _globalTop ?? MediaQuery.paddingOf(context).top;

          return CustomMultiChildLayout(
            key: _layoutKey,
            delegate: _PermissionLayoutDelegate(
              frameCenterY: screenHeight / 2 - globalTop,
              frameSize: frameSize,
              // Arrow ≈ 60 visible px + privacy line; checklist needs more.
              belowReserve: showArrow ? 120 : 200,
              arrowOverlap: showArrow ? 26 : 0,
            ),
            children: [
              LayoutId(
                id: _Slot.header,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.md,
                    AppSpacing.screenGutter,
                    0,
                  ),
                  child: OnboardingStepHeaderWidget(
                    title: context.tr('permission_title'),
                    description: context.tr(
                      usesSystemPrompt ? 'permission_description_ios' : 'permission_description_android',
                    ),
                  ),
                ).animate(delay: 90.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
              ),
              LayoutId(
                id: _Slot.frame,
                child:
                    SystemPromptFrameWidget(
                          isGranted: isGranted,
                          child: usesSystemPrompt
                              ? const GhostSystemDialogWidget()
                              : access == null
                              ? const SizedBox.shrink()
                              : _CardFlipSwitcher(
                                  showBack: !showAndroidCard,
                                  front: SinklyPermissionCardWidget(
                                    onAllow: _acceptAndroidCard,
                                    onLater: _cubit.nextStep,
                                  ),
                                  back: AndroidSettingsToggleGuideWidget(
                                    access: access,
                                    openingIn: _openingSettings
                                        ? ScreenTimePermissionStepWidget.openSettingsDelay
                                        : null,
                                  ),
                                ),
                        )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack, duration: 650.ms),
              ),
              LayoutId(
                id: _Slot.below,
                child: _BelowFrame(
                  access: access,
                  usesSystemPrompt: usesSystemPrompt,
                  isGranted: isGranted,
                  showArrow: showArrow,
                  failureKey: status == OnboardingRequestStatus.failure ? failureKey : null,
                ),
              ),
              LayoutId(
                id: _Slot.cta,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.xs,
                    AppSpacing.screenGutter,
                    AppSpacing.md,
                  ),
                  child: AnimatedSize(
                    duration: AppDurations.medium,
                    curve: Curves.easeOutCubic,
                    // Android intro: the card's own buttons are the CTA.
                    child: showAndroidCard
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomPrimaryButton(
                                label: ctaLabel,
                                onPressed: onCtaPressed,
                                isLoading: isRequesting,
                                trailingIcon: !isGranted && !usesSystemPrompt ? Icons.open_in_new_rounded : null,
                              ),
                              if (!isGranted) ...[
                                const SizedBox(height: AppSpacing.xs),
                                TextButton(
                                  onPressed: _cubit.nextStep,
                                  child: Text(
                                    context.tr('maybe_later'),
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ).animate(delay: 260.ms).fadeIn(duration: 400.ms).slideY(begin: 0.25, curve: Curves.easeOutCubic),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Arrow (at the popup / card) or the Android checklist, status hint, then
/// the privacy promise pinned just above the CTA.
class _BelowFrame extends StatelessWidget {
  const _BelowFrame({
    required this.access,
    required this.usesSystemPrompt,
    required this.isGranted,
    required this.showArrow,
    required this.failureKey,
  });

  final ScreenTimeAccessModel? access;
  final bool usesSystemPrompt;
  final bool isGranted;
  final bool showArrow;
  final String? failureKey;

  @override
  Widget build(BuildContext context) {
    final top = <Widget>[
      if (showArrow)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: PermissionPointerArrowWidget(label: context.tr('permission_tap_hint')),
        ),
      if (!usesSystemPrompt && !showArrow && access != null) ...[
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
          child: AndroidRequirementChecklistWidget(access: access!),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
      ],
      AnimatedSize(
        duration: AppDurations.medium,
        child: failureKey == null || isGranted
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.sm, AppSpacing.screenGutter, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.tr(failureKey!),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ).animate().shakeX(hz: 4, amount: 3, duration: 400.ms),
              ),
      ),
    ];

    final privacy = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.sm, AppSpacing.screenGutter, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.verified_user_rounded, size: 15, color: AppColors.primaryInk),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.tr(usesSystemPrompt ? 'permission_privacy_ios' : 'permission_privacy_android'),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms);

    // Fill the slot (privacy note sits right above the CTA); on very short
    // screens it clips quietly instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: Column(children: [...top, const Spacer(), privacy])),
        ),
      ),
    );
  }
}

/// 3D card flip between Sinkly's card ([front]) and the Settings replica
/// ([back]): the old face turns away to 90°, the new one turns in from -90°.
class _CardFlipSwitcher extends StatelessWidget {
  const _CardFlipSwitcher({required this.showBack, required this.front, required this.back});

  final bool showBack;
  final Widget front;
  final Widget back;

  static Widget _flip(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // Incoming runs 0→1 (forward), outgoing 1→0 (reverse).
        final isIncoming = animation.status == AnimationStatus.forward || animation.status == AnimationStatus.completed;
        final angle = (1 - animation.value) * math.pi * (isIncoming ? -1 : 1);
        if (angle.abs() > math.pi / 2) return const SizedBox.shrink();
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 760),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: _flip,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(showBack), child: showBack ? back : front),
    );
  }
}

enum _Slot { header, frame, below, cta }

/// Header on top, CTA at the bottom, and the frame centred on the SCREEN
/// (where the OS draws its alert) whenever there is room for it.
class _PermissionLayoutDelegate extends MultiChildLayoutDelegate {
  _PermissionLayoutDelegate({
    required this.frameCenterY,
    required this.frameSize,
    required this.belowReserve,
    required this.arrowOverlap,
  });

  /// Screen centre, in this layout's coordinates.
  final double frameCenterY;
  final Size frameSize;

  /// Space kept under the frame for the arrow / checklist / privacy note.
  final double belowReserve;
  final double arrowOverlap;

  @override
  void performLayout(Size size) {
    // Unbounded height: header/CTA columns hug their content (a bounded max
    // lets a Column stretch over the whole step and squash the frame to 0).
    final fullWidth = BoxConstraints.tightFor(width: size.width);
    final header = layoutChild(_Slot.header, fullWidth);
    final cta = layoutChild(_Slot.cta, fullWidth);
    final ctaTop = size.height - cta.height;
    final minTop = header.height + AppSpacing.lg;

    // Short screens / huge text: shrink the frame (its content scales down)
    // rather than clip what sits under it.
    final frameHeight = math.max(0.0, math.min(frameSize.height, ctaTop - minTop - belowReserve));
    final maxTop = math.max(minTop, ctaTop - belowReserve - frameHeight);
    final top = (frameCenterY - frameHeight / 2).clamp(minTop, maxTop);

    layoutChild(_Slot.frame, BoxConstraints.tight(Size(frameSize.width, frameHeight)));
    final belowTop = top + frameHeight - arrowOverlap;
    layoutChild(_Slot.below, fullWidth.copyWith(minHeight: 0, maxHeight: math.max(0.0, ctaTop - belowTop)));

    positionChild(_Slot.header, Offset.zero);
    positionChild(_Slot.frame, Offset((size.width - frameSize.width) / 2, top));
    positionChild(_Slot.below, Offset(0, belowTop));
    positionChild(_Slot.cta, Offset(0, ctaTop));
  }

  @override
  bool shouldRelayout(_PermissionLayoutDelegate oldDelegate) =>
      oldDelegate.frameCenterY != frameCenterY ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.belowReserve != belowReserve ||
      oldDelegate.arrowOverlap != arrowOverlap;
}

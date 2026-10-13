import 'package:flutter/material.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_widget.dart';
import '../../../data/models/screen_time_access_model.dart';

/// Android has no permission popup for app blocking: "Display over other
/// apps" and "Usage access" are switches inside Settings. This mini replica
/// of the exact Settings page Sinkly is about to open (app row + switch,
/// with a looping tap) shows the user what to do there.
///
/// When [openingIn] is set, a progress line fills for that long ("Opening
/// Settings…") before Sinkly opens the page by itself.
class AndroidSettingsToggleGuideWidget extends StatelessWidget {
  const AndroidSettingsToggleGuideWidget({super.key, required this.access, this.openingIn});

  final ScreenTimeAccessModel access;
  final Duration? openingIn;

  static String titleKey(ScreenTimeRequirement requirement) => requirement == ScreenTimeRequirement.usageAccess
      ? 'permission_android_usage_title'
      : 'permission_android_overlay_title';

  static String toggleKey(ScreenTimeRequirement requirement) => requirement == ScreenTimeRequirement.usageAccess
      ? 'permission_android_usage_toggle'
      : 'permission_android_overlay_toggle';

  static String reasonKey(ScreenTimeRequirement requirement) => requirement == ScreenTimeRequirement.usageAccess
      ? 'permission_android_usage_reason'
      : 'permission_android_overlay_reason';

  @override
  Widget build(BuildContext context) {
    final requirement = access.nextMissing ?? access.requirements.last;
    final total = access.requirements.length;
    final current = (access.requirements.indexOf(requirement) + 1).clamp(1, total);

    return Center(
      child: AnimatedSwitcher(
        duration: AppDurations.slow,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(requirement),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (total > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: const BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadii.pillAll),
                child: Text(
                  context.tr('permission_android_step_counter', {'current': '$current', 'total': '$total'}),
                  style: AppTextStyles.label.copyWith(color: AppColors.primaryInk, letterSpacing: 0.2),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            _SettingsPageReplica(
              title: context.tr(titleKey(requirement)),
              toggleLabel: context.tr(toggleKey(requirement)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('permission_android_find_hint'),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            if (openingIn != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _OpeningSettingsProgress(duration: openingIn!),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpeningSettingsProgress extends StatelessWidget {
  const _OpeningSettingsProgress({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('permission_opening_settings'), style: AppTextStyles.caption.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: AppRadii.pillAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: duration,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryInk),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPageReplica extends StatelessWidget {
  const _SettingsPageReplica({required this.title, required this.toggleLabel});

  final String title;
  final String toggleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings app bar.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  context.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // App header.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const SinklyLogoWidget(size: 15, showWordmark: false),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(AppConstants.appName, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: AppSpacing.md, indent: AppSpacing.sm, endIndent: AppSpacing.sm),
          // The switch the user has to flip.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    toggleLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const _LoopingTapSwitch(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Material-3-style switch that keeps getting tapped on: off → finger tap →
/// on → hold → reset.
class _LoopingTapSwitch extends StatefulWidget {
  const _LoopingTapSwitch();

  @override
  State<_LoopingTapSwitch> createState() => _LoopingTapSwitchState();
}

class _LoopingTapSwitchState extends State<_LoopingTapSwitch> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  static const _onColor = AppColors.primaryInk;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 0–.35 off · .35–.5 flip on · .5–.9 on · .9–1 reset.
        final on = t < 0.35
            ? 0.0
            : t < 0.5
            ? Curves.easeOutCubic.transform((t - 0.35) / 0.15)
            : t < 0.9
            ? 1.0
            : 1 - (t - 0.9) / 0.1;
        final press = t > 0.25 && t < 0.45 ? 1 - ((t - 0.35).abs() / 0.1).clamp(0.0, 1.0) : 0.0;
        final fingerOpacity = t < 0.15 ? t / 0.15 : (t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.15).clamp(0.0, 1.0));

        return SizedBox(
          width: 60,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Track.
              Container(
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.divider, _onColor, on),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: Color.lerp(AppColors.inkMuted, _onColor, on)!, width: 1.6),
                ),
              ),
              // Thumb.
              Align(
                alignment: Alignment.lerp(
                  const Alignment(-0.42, 0),
                  const Alignment(0.42, 0),
                  context.isRtl ? 1 - on : on,
                )!,
                child: Container(
                  width: 14 + 6 * on,
                  height: 14 + 6 * on,
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.inkMuted, Colors.white, on),
                    shape: BoxShape.circle,
                  ),
                  child: on > 0.6 ? Icon(Icons.check_rounded, size: 13 * on, color: _onColor) : null,
                ),
              ),
              // Tap ripple + finger.
              Positioned(
                left: 18,
                top: 18,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: fingerOpacity,
                    child: Transform.translate(
                      offset: Offset(0, 4 - 4 * press),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -4,
                            top: -10,
                            child: Container(
                              width: 22 + 14 * press,
                              height: 22 + 14 * press,
                              transform: Matrix4.translationValues(-7 * press, -7 * press, 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _onColor.withValues(alpha: 0.18 * press),
                              ),
                            ),
                          ),
                          const Text('👆', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Below the frame on Android: both grants with their live state.
class AndroidRequirementChecklistWidget extends StatelessWidget {
  const AndroidRequirementChecklistWidget({super.key, required this.access});

  final ScreenTimeAccessModel access;

  @override
  Widget build(BuildContext context) {
    final next = access.nextMissing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final requirement in access.requirements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _ChecklistRow(
              title: context.tr(AndroidSettingsToggleGuideWidget.titleKey(requirement)),
              reason: context.tr(AndroidSettingsToggleGuideWidget.reasonKey(requirement)),
              isDone: access.isRequirementGranted(requirement),
              isActive: requirement == next,
            ),
          ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.title, required this.reason, required this.isDone, required this.isActive});

  final String title;
  final String reason;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? AppColors.glassFillStrong : AppColors.glassFill,
        borderRadius: AppRadii.mediumAll,
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.5)
              : isActive
              ? AppColors.primary
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppDurations.medium,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Container(
              key: ValueKey(isDone),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDone ? AppGradients.success : null,
                border: isDone
                    ? null
                    : Border.all(color: isActive ? AppColors.primaryInk : AppColors.inkMuted, width: 2),
              ),
              child: isDone ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 14,
                    color: isDone ? AppColors.inkSoft : AppColors.ink,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.inkMuted,
                  ),
                ),
                Text(reason, style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

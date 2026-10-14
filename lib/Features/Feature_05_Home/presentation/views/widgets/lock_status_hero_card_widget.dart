import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/app_icons_wrap_widget.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/sunburst_rays_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/rising_emoji_particles_widget.dart';

/// The hero of the Home tab, starring the heroine. Two moods, cross-faded:
///  • All clear: she happily scrolls her phone (guilt-free, hearts float up),
///    waves, then hugs herself with joy — "you earned this".
///  • Locked: she points at the "start" button, scrubs a plate, then cheers
///    the user on — an invitation, never a scolding.
/// Each mood loops through its little acts; tapping her skips ahead.
class LockStatusHeroCardWidget extends StatelessWidget {
  const LockStatusHeroCardWidget({
    super.key,
    required this.lockStatus,
    required this.blockedApps,
    required this.now,
    required this.sprintMinutes,
    required this.onStartSinkSprint,
  });

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final DateTime now;
  final int sprintMinutes;
  final VoidCallback onStartSinkSprint;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.slow,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
      ),
      child: lockStatus.isLocked
          ? _LockedHeroCard(
              key: const ValueKey('locked'),
              lockStatus: lockStatus,
              blockedApps: blockedApps,
              sprintMinutes: sprintMinutes,
              onStart: onStartSinkSprint,
            )
          : _UnlockedHeroCard(
              key: const ValueKey('unlocked'),
              lockStatus: lockStatus,
              blockedApps: blockedApps,
              now: now,
            ),
    );
  }
}

// ── Locked ──────────────────────────────────────────────────────────────────

class _LockedHeroCard extends StatelessWidget {
  const _LockedHeroCard({
    super.key,
    required this.lockStatus,
    required this.blockedApps,
    required this.sprintMinutes,
    required this.onStart,
  });

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final int sprintMinutes;
  final VoidCallback onStart;

  /// Points at the button → scrubs a plate → cheers.
  static const List<_HeroineAct> _acts = [
    _HeroineAct(
      pose: HeroinePose.present,
      motion: HeroineMotion.beckon,
      emoji: '👇',
      duration: Duration(milliseconds: 3800),
    ),
    _HeroineAct(
      pose: HeroinePose.washJoy,
      motion: HeroineMotion.scrub,
      prop: HeroineProp.plate,
      emoji: '🧽',
      particles: ['✨', '💧', '✨', '💧'],
      duration: Duration(milliseconds: 4200),
    ),
    _HeroineAct(
      pose: HeroinePose.cheer,
      motion: HeroineMotion.cheer,
      emoji: '💪',
      particles: ['💪', '✨', '💙'],
      duration: Duration(milliseconds: 3200),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mealName = lockStatus.lockingMeal == null
        ? context.tr('home_locked_manual')
        : context.tr(lockStatus.lockingMeal!.translationKey);
    return _HeroCardLayout(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF2FFFFFF), Color(0xE6FFF1E6)],
      ),
      rayColor: const Color(0xFFFFC36B),
      acts: _acts,
      header: [
        _StatusPill(label: context.tr('home_status_locked'), color: AppColors.danger, background: AppColors.dangerSoft),
        if (lockStatus.lockedSince != null) ...[
          const SizedBox(height: 4),
          Text(
            context.tr('home_locked_since', {
              'time': AppFunctions.formatDateTimeClock(context, lockStatus.lockedSince!),
            }),
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr('home_locked_title', {'meal': mealName}), style: AppTextStyles.title),
        const SizedBox(height: 4),
        Text(context.tr('home_locked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
      ],
      footer: [
        if (blockedApps.isNotEmpty) ...[
          AppIconsWrapWidget(apps: blockedApps, size: 38, showLockBadge: true),
          const SizedBox(height: AppSpacing.lg),
        ],
        CustomPrimaryButton(
          label: context.tr('home_start_sprint_cta', {'duration': context.minutes(sprintMinutes)}),
          icon: Icons.cleaning_services_rounded,
          showShimmer: true,
          onPressed: onStart,
        ),
      ],
    );
  }
}

// ── All clear ───────────────────────────────────────────────────────────────

class _UnlockedHeroCard extends StatelessWidget {
  const _UnlockedHeroCard({super.key, required this.lockStatus, required this.blockedApps, required this.now});

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final DateTime now;

  /// Happy, guilt-free scrolling (hearts float up from the phone).
  static const HeroinePose _happyScroll = HeroinePose(
    leftHand: Offset(110, 160),
    rightHand: Offset(130, 160),
    lookDown: 0.8,
    headTilt: 0.1,
    smile: 0.9,
    mouthOpen: 0.15,
    blush: 0.6,
  );

  /// Scrolls happily → waves at the user → hugs herself with joy.
  static const List<_HeroineAct> _acts = [
    _HeroineAct(
      pose: _happyScroll,
      motion: HeroineMotion.scroll,
      prop: HeroineProp.phone,
      emoji: '📱',
      particles: ['💙', '✨', '💙', '💛'],
      duration: Duration(milliseconds: 5200),
    ),
    _HeroineAct(
      pose: HeroinePose.waveJoy,
      motion: HeroineMotion.wave,
      emoji: '👋',
      duration: Duration(milliseconds: 3400),
    ),
    _HeroineAct(
      pose: HeroinePose.adore,
      motion: HeroineMotion.bounce,
      emoji: '✨',
      duration: Duration(milliseconds: 3600),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _HeroCardLayout(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF2FFFFFF), Color(0xE6E3F8EF)],
      ),
      rayColor: AppColors.success,
      acts: _acts,
      header: [
        _StatusPill(
          label: context.tr('home_status_unlocked'),
          color: AppColors.success,
          background: AppColors.successSoft,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr('home_unlocked_title'), style: AppTextStyles.title),
        const SizedBox(height: 4),
        Text(context.tr('home_unlocked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
      ],
      footer: [_NextLockStrip(lockStatus: lockStatus, blockedApps: blockedApps, now: now)],
    );
  }
}

class _NextLockStrip extends StatelessWidget {
  const _NextLockStrip({required this.lockStatus, required this.blockedApps, required this.now});

  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final nextAt = lockStatus.nextLockAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: AppRadii.mediumAll,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primaryInk),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: nextAt == null
                ? Text(context.tr('home_no_upcoming_lock'), style: AppTextStyles.bodyStrong.copyWith(fontSize: 14))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home_next_lock', {
                          'meal': context.tr(lockStatus.nextLockMeal?.translationKey ?? 'meal_dinner'),
                          'time': AppFunctions.formatDateTimeClock(context, nextAt),
                        }),
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                      ),
                      Text(
                        context.tr('home_next_lock_in', {
                          'duration': AppFunctions.formatCompactDuration(context, nextAt.difference(now)),
                        }),
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
          ),
          SizedBox(
            width: 26.0 + (blockedApps.take(3).length - 1).clamp(0, 2) * 14,
            height: 26,
            child: Stack(
              children: [
                for (final (index, app) in blockedApps.take(3).indexed)
                  PositionedDirectional(start: index * 14.0, child: BlockableAppIconWidget(app: app, size: 26)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared layout + the heroine's little stage ─────────────────────────────

/// Card: text on the start side, the heroine standing on the end side (feet
/// on the line where the text block ends), then the footer full-width.
class _HeroCardLayout extends StatelessWidget {
  const _HeroCardLayout({
    required this.gradient,
    required this.rayColor,
    required this.acts,
    required this.header,
    required this.footer,
  });

  final Gradient gradient;
  final Color rayColor;
  final List<_HeroineAct> acts;
  final List<Widget> header;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      gradient: gradient,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg - 2, AppSpacing.md, AppSpacing.lg - 2, AppSpacing.lg - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              // She takes about a third of the card, never less than readable.
              final heroineWidth = (box.maxWidth * 0.36).clamp(86.0, 118.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: header),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _HeroineStage(width: heroineWidth, acts: acts, rayColor: rayColor),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ...footer,
        ],
      ),
    );
  }
}

/// One beat of the heroine's loop.
class _HeroineAct {
  const _HeroineAct({
    required this.pose,
    required this.motion,
    required this.emoji,
    required this.duration,
    this.prop = HeroineProp.none,
    this.particles,
  });

  final HeroinePose pose;
  final HeroineMotion motion;
  final HeroineProp prop;

  /// Floating "thought" next to her head (what she's up to).
  final String emoji;

  /// Optional little burst rising from her hands.
  final List<String>? particles;
  final Duration duration;
}

class _HeroineStage extends StatefulWidget {
  const _HeroineStage({required this.width, required this.acts, required this.rayColor});

  final double width;
  final List<_HeroineAct> acts;
  final Color rayColor;

  @override
  State<_HeroineStage> createState() => _HeroineStageState();
}

class _HeroineStageState extends State<_HeroineStage> {
  int _index = 0;
  Timer? _timer;

  _HeroineAct get _act => widget.acts[_index % widget.acts.length];

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_act.duration, () {
      if (!mounted) return;
      setState(() => _index++);
      _scheduleNext();
    });
  }

  void _skipAhead() {
    AppFunctions.lightHaptic();
    setState(() => _index++);
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final act = _act;
    final width = widget.width;
    final height = HeroineCharacterWidget.heightFor(width);
    final particles = act.particles;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Slowly turning light behind her (the card clips its edges).
          Positioned(
            left: -width * 0.2,
            right: -width * 0.2,
            top: height * 0.05 - width * 0.2,
            height: width * 1.4,
            child: Opacity(opacity: 0.8, child: SunburstRaysWidget(color: widget.rayColor, rayCount: 12)),
          ),
          Semantics(
            button: true,
            label: context.tr('lock_overlay_next_tip'),
            child: GestureDetector(
              onTap: _skipAhead,
              child: HeroineCharacterWidget(width: width, pose: act.pose, motion: act.motion, prop: act.prop),
            ),
          ),
          if (particles != null)
            Positioned(
              left: width / 2 - 30,
              top: height * 0.42,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: RisingEmojiParticlesWidget(
                  key: ValueKey(_index),
                  emojis: particles,
                  rise: height * 0.45,
                  spread: 24,
                  fontSize: 13,
                  interval: const Duration(milliseconds: 380),
                  lifetime: const Duration(milliseconds: 1600),
                ),
              ),
            ),
          // Floating "thought" beside her head, on the text side but inside
          // her own area so it never covers the title.
          PositionedDirectional(
            start: -4,
            top: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 460),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _ThoughtEmoji(key: ValueKey(act.emoji), emoji: act.emoji),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThoughtEmoji extends StatelessWidget {
  const _ThoughtEmoji({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primarySoft, width: 1.5),
            boxShadow: AppShadows.soft,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: AppRadii.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.75, end: 1.2, duration: 900.ms, curve: Curves.easeInOut),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PREVIOUS DESIGN (before 2026-10-14), kept commented out until the new
//  design is approved. To restore: replace this whole file with the block
//  below, uncommented (remove the leading "// " from every line).
// ═══════════════════════════════════════════════════════════════════════════
//
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
//
// import '../../../../../core/models/shared_core_models.dart';
// import '../../../../../core/utils/app_localizations.dart';
// import '../../../../../core/utils/functions/app_functions.dart';
// import '../../../../../core/utils/style.dart';
// import '../../../../../core/widgets/blockable_app_icon_widget.dart';
// import '../../../../../core/widgets/app_icons_wrap_widget.dart';
// import '../../../../../core/widgets/custom_card_container.dart';
// import '../../../../../core/widgets/custom_primary_button.dart';
//
// /// The hero of the Home tab: either "Apps locked → clean the sink" or
// /// "All clear → next lock at …". Cross-fades between both states.
// class LockStatusHeroCardWidget extends StatelessWidget {
//   const LockStatusHeroCardWidget({
//     super.key,
//     required this.lockStatus,
//     required this.blockedApps,
//     required this.now,
//     required this.sprintMinutes,
//     required this.onStartSinkSprint,
//   });
//
//   final LockStatusModel lockStatus;
//   final List<BlockableAppModel> blockedApps;
//   final DateTime now;
//   final int sprintMinutes;
//   final VoidCallback onStartSinkSprint;
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: AppDurations.slow,
//       switchInCurve: Curves.easeOutCubic,
//       transitionBuilder: (child, animation) => FadeTransition(
//         opacity: animation,
//         child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
//       ),
//       child: lockStatus.isLocked
//           ? _LockedContent(
//               key: const ValueKey('locked'),
//               lockStatus: lockStatus,
//               blockedApps: blockedApps,
//               sprintMinutes: sprintMinutes,
//               onStart: onStartSinkSprint,
//             )
//           : _UnlockedContent(
//               key: const ValueKey('unlocked'),
//               lockStatus: lockStatus,
//               blockedApps: blockedApps,
//               now: now,
//             ),
//     );
//   }
// }
//
// class _LockedContent extends StatelessWidget {
//   const _LockedContent({
//     super.key,
//     required this.lockStatus,
//     required this.blockedApps,
//     required this.sprintMinutes,
//     required this.onStart,
//   });
//
//   final int sprintMinutes;
//   final LockStatusModel lockStatus;
//   final List<BlockableAppModel> blockedApps;
//   final VoidCallback onStart;
//
//   @override
//   Widget build(BuildContext context) {
//     final mealName = lockStatus.lockingMeal == null
//         ? context.tr('home_locked_manual')
//         : context.tr(lockStatus.lockingMeal!.translationKey);
//     return CustomCardContainer(
//       gradient: const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [Color(0xF2FFFFFF), Color(0xE6FFF1E6)],
//       ),
//       padding: const EdgeInsets.all(AppSpacing.lg - 2),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                     width: 52,
//                     height: 52,
//                     decoration: const BoxDecoration(
//                       gradient: AppGradients.ink,
//                       borderRadius: AppRadii.mediumAll,
//                       boxShadow: AppShadows.soft,
//                     ),
//                     child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
//                   )
//                   .animate(onPlay: (c) => c.repeat(reverse: true))
//                   .scaleXY(begin: 1, end: 1.06, duration: 900.ms, curve: Curves.easeInOut),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _StatusPill(
//                       label: context.tr('home_status_locked'),
//                       color: AppColors.danger,
//                       background: AppColors.dangerSoft,
//                     ),
//                     const SizedBox(height: 4),
//                     if (lockStatus.lockedSince != null)
//                       Text(
//                         context.tr('home_locked_since', {
//                           'time': AppFunctions.formatDateTimeClock(context, lockStatus.lockedSince!),
//                         }),
//                         style: AppTextStyles.caption.copyWith(fontSize: 12),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Text(context.tr('home_locked_title', {'meal': mealName}), style: AppTextStyles.title),
//           const SizedBox(height: 4),
//           Text(context.tr('home_locked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
//           const SizedBox(height: AppSpacing.md),
//           AppIconsWrapWidget(apps: blockedApps, size: 38, showLockBadge: true),
//           const SizedBox(height: AppSpacing.lg),
//           CustomPrimaryButton(
//             label: context.tr('home_start_sprint_cta', {'duration': context.minutes(sprintMinutes)}),
//             icon: Icons.cleaning_services_rounded,
//             showShimmer: true,
//             onPressed: onStart,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _UnlockedContent extends StatelessWidget {
//   const _UnlockedContent({super.key, required this.lockStatus, required this.blockedApps, required this.now});
//
//   final LockStatusModel lockStatus;
//   final List<BlockableAppModel> blockedApps;
//   final DateTime now;
//
//   @override
//   Widget build(BuildContext context) {
//     final nextAt = lockStatus.nextLockAt;
//     return CustomCardContainer(
//       gradient: const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [Color(0xF2FFFFFF), Color(0xE6E3F8EF)],
//       ),
//       padding: const EdgeInsets.all(AppSpacing.lg - 2),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 52,
//                 height: 52,
//                 decoration: const BoxDecoration(
//                   gradient: AppGradients.success,
//                   borderRadius: AppRadii.mediumAll,
//                   boxShadow: AppShadows.soft,
//                 ),
//                 child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 26),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: _StatusPill(
//                   label: context.tr('home_status_unlocked'),
//                   color: AppColors.success,
//                   background: AppColors.successSoft,
//                 ),
//               ),
//               const Text(
//                 '✨',
//                 style: TextStyle(fontSize: 26),
//               ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.05, end: 0.05, duration: 1200.ms),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Text(context.tr('home_unlocked_title'), style: AppTextStyles.title),
//           const SizedBox(height: 4),
//           Text(context.tr('home_unlocked_subtitle'), style: AppTextStyles.body.copyWith(fontSize: 14)),
//           const SizedBox(height: AppSpacing.md),
//           Container(
//             padding: const EdgeInsets.all(AppSpacing.sm),
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.85),
//               borderRadius: AppRadii.mediumAll,
//               boxShadow: AppShadows.soft,
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.schedule_rounded, color: AppColors.primaryInk),
//                 const SizedBox(width: AppSpacing.xs),
//                 Expanded(
//                   child: nextAt == null
//                       ? Text(
//                           context.tr('home_no_upcoming_lock'),
//                           style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
//                         )
//                       : Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               context.tr('home_next_lock', {
//                                 'meal': context.tr(lockStatus.nextLockMeal?.translationKey ?? 'meal_dinner'),
//                                 'time': AppFunctions.formatDateTimeClock(context, nextAt),
//                               }),
//                               style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
//                             ),
//                             Text(
//                               context.tr('home_next_lock_in', {
//                                 'duration': AppFunctions.formatCompactDuration(context, nextAt.difference(now)),
//                               }),
//                               style: AppTextStyles.caption.copyWith(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                 ),
//                 SizedBox(
//                   width: 26.0 + (blockedApps.take(3).length - 1).clamp(0, 2) * 14,
//                   height: 26,
//                   child: Stack(
//                     children: [
//                       for (final (index, app) in blockedApps.take(3).indexed)
//                         PositionedDirectional(
//                           start: index * 14.0,
//                           child: BlockableAppIconWidget(app: app, size: 26),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _StatusPill extends StatelessWidget {
//   const _StatusPill({required this.label, required this.color, required this.background});
//
//   final String label;
//   final Color color;
//   final Color background;
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: AlignmentDirectional.centerStart,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(color: background, borderRadius: AppRadii.pillAll),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 7,
//               height: 7,
//               decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//             ),
//             const SizedBox(width: 6),
//             Flexible(
//               child: Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 11)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

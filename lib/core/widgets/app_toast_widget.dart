import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/style.dart';
import 'custom_card_container.dart';

/// Mood of a toast: drives its colour, icon, haptic and motion.
enum AppToastTone {
  /// Neutral note (sky).
  info(icon: Icons.info_rounded, color: AppColors.primaryInk, soft: AppColors.primarySoft),

  /// Something worked (mint) — the badge pops.
  success(icon: Icons.check_rounded, color: AppColors.success, soft: AppColors.successSoft),

  /// Something needs another try (coral) — the card shakes "no".
  error(icon: Icons.priority_high_rounded, color: AppColors.danger, soft: AppColors.dangerSoft);

  const AppToastTone({required this.icon, required this.color, required this.soft});

  final IconData icon;
  final Color color;
  final Color soft;
}

/// Sinkly's temporary message: a floating glass card with a coloured badge,
/// centred text and a thin countdown line. Replaces Material's black SnackBar.
///
/// Only one toast is visible at a time; a new one replaces the current one
/// (so a repeated error re-enters and shakes again). Tap or swipe down to
/// dismiss early.
abstract final class AppToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message, {AppToastTone tone = AppToastTone.info}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AppToastWidget(
        key: UniqueKey(),
        message: message,
        tone: tone,
        onDismissed: () {
          if (identical(_entry, entry)) _entry = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Removes the visible toast at once (no exit animation).
  static void hide() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class AppToastWidget extends StatefulWidget {
  const AppToastWidget({super.key, required this.message, required this.tone, required this.onDismissed});

  final String message;
  final AppToastTone tone;
  final VoidCallback onDismissed;

  @override
  State<AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<AppToastWidget> with TickerProviderStateMixin {
  static const double _badgeSize = 40;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Drives the countdown line and auto-dismiss.
  late final AnimationController _life = AnimationController(vsync: this, duration: _visibleFor);

  late final Animation<double> _slide = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _badgePop = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.3, 1, curve: Curves.elasticOut),
    reverseCurve: Curves.easeIn,
  );

  Timer? _shakeDelay;
  bool _closing = false;

  /// Long enough to read: ~35 ms per character, between 2.8 s and 5.2 s.
  Duration get _visibleFor => Duration(milliseconds: (2600 + widget.message.length * 35).clamp(2800, 5200));

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _life
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      })
      ..forward();

    if (widget.tone == AppToastTone.error) {
      HapticFeedback.mediumImpact();
      // Shake once the card has landed.
      _shakeDelay = Timer(const Duration(milliseconds: 280), () {
        if (mounted && !MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
      });
    } else if (widget.tone == AppToastTone.success) {
      HapticFeedback.lightImpact();
    }
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    _life.stop();
    _entrance.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _shakeDelay?.cancel();
    _entrance.dispose();
    _shake.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // Above the keyboard when it's open, otherwise above the floating tab bar.
    final bottom = keyboard > 0
        ? keyboard + AppSpacing.md
        : media.viewPadding.bottom + AppSpacing.mainTabBarHeight + AppSpacing.lg;

    return Positioned(
      left: AppSpacing.screenGutter,
      right: AppSpacing.screenGutter,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AnimatedBuilder(
            animation: Listenable.merge([_entrance, _shake]),
            builder: (context, child) {
              final shake = _shake.value;
              // Three quick, fading "no" swings.
              final dx = math.sin(shake * math.pi * 6) * 9 * (1 - shake);
              final dy = (1 - _slide.value) * 40;
              return Opacity(
                opacity: _entrance.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(scale: 0.94 + 0.06 * _slide.value, child: child),
                ),
              );
            },
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final tone = widget.tone;
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 120) _dismiss();
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _badgeSize / 2),
                child: CustomCardContainer(
                  width: double.infinity,
                  useSharedBackdrop: false,
                  fillColor: AppColors.glassFillStrong,
                  borderRadius: AppRadii.cardAll,
                  borderColor: tone.color.withValues(alpha: 0.28),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    _badgeSize / 2 + AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  shadows: [
                    ...AppShadows.floating,
                    BoxShadow(
                      color: tone.color.withValues(alpha: 0.22),
                      blurRadius: 30,
                      spreadRadius: -10,
                      offset: const Offset(0, 14),
                    ),
                  ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CountdownLine(life: _life, tone: tone),
                    ],
                  ),
                ),
              ),
              ScaleTransition(scale: _badgePop, child: _ToneBadge(tone: tone, size: _badgeSize)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round coloured badge that sits half above the card.
class _ToneBadge extends StatelessWidget {
  const _ToneBadge({required this.tone, required this.size});

  final AppToastTone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(tone.color, Colors.white, 0.35)!, tone.color],
      ),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(color: tone.color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: -3, offset: const Offset(0, 6)),
      ],
    ),
    child: Icon(tone.icon, color: Colors.white, size: size * 0.5),
  );
}

/// Thin pill that empties while the toast is visible.
class _CountdownLine extends StatelessWidget {
  const _CountdownLine({required this.life, required this.tone});

  final Animation<double> life;
  final AppToastTone tone;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    height: 3,
    child: ClipRRect(
      borderRadius: AppRadii.pillAll,
      child: ColoredBox(
        color: tone.soft,
        child: AnimatedBuilder(
          animation: life,
          builder: (context, _) => FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1 - life.value,
            child: ColoredBox(color: tone.color.withValues(alpha: 0.7)),
          ),
        ),
      ),
    ),
  );
}

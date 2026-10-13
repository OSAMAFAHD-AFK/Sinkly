import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Screen 11 visual — the Sinkly loop as a vertical, step-by-step timeline:
/// meal ends → apps lock → timed sink sprint → photo → guilt-free reward.
///
/// One continuous cycle: a water drop flows down the line, each step lights
/// up as the drop arrives (ripple + sky fill + bright text), the reward
/// bursts into sparkles, then everything fades softly and the loop restarts.
class SinklyFormulaFlowWidget extends StatefulWidget {
  const SinklyFormulaFlowWidget({super.key, required this.blockedApps});

  final List<BlockableAppModel> blockedApps;

  @override
  State<SinklyFormulaFlowWidget> createState() => _SinklyFormulaFlowWidgetState();
}

class _SinklyFormulaFlowWidgetState extends State<SinklyFormulaFlowWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))
    ..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <({String emoji, String title, String subtitle, Widget? trailing})>[
      (
        emoji: '🍝',
        title: context.tr('formula_step_meal_title'),
        subtitle: context.tr('formula_step_meal_subtitle'),
        trailing: null,
      ),
      (
        emoji: '🔒',
        title: context.tr('formula_step_lock_title'),
        subtitle: context.tr('formula_step_lock_subtitle'),
        trailing: _AppStack(apps: widget.blockedApps),
      ),
      (
        emoji: '🧽',
        title: context.tr('formula_step_sprint_title', {
          'duration': context.minutes(AppConstants.sinkSprintDuration.inMinutes),
        }),
        subtitle: context.tr('formula_step_sprint_subtitle'),
        trailing: null,
      ),
      (
        emoji: '📸',
        title: context.tr('formula_step_photo_title'),
        subtitle: context.tr('formula_step_photo_subtitle'),
        trailing: null,
      ),
      (
        emoji: '🎉',
        title: context.tr('formula_step_reward_title'),
        subtitle: context.tr('formula_step_reward_subtitle'),
        trailing: null,
      ),
    ];
    // Reduced motion: show the completed journey, no loop.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return CustomCardContainer(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) {
                    final timeline = _FlowTimeline(reduceMotion ? 0.85 : _loop.value, steps.length);
                    return _FormulaStepRow(
                      emoji: steps[i].emoji,
                      title: steps[i].title,
                      subtitle: steps[i].subtitle,
                      trailing: steps[i].trailing,
                      isLast: i == steps.length - 1,
                      isReward: i == steps.length - 1,
                      activation: timeline.activation(i),
                      ripple: reduceMotion ? 0 : timeline.ripple(i),
                      flow: i == steps.length - 1 ? 0 : timeline.flow(i),
                    );
                  },
                )
                .animate(delay: (250 + i * 220).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: context.flipX(0.1), curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// Maps the loop value (0…1) to per-step progress.
///
/// Step *i* is reached at [arrival]; the drop travels the connector between
/// consecutive arrivals; after the last step there's a short hold, then a
/// soft global fade ([reset]) so the next cycle starts clean.
class _FlowTimeline {
  _FlowTimeline(this.t, this.count);

  final double t;
  final int count;

  static const double _first = 0.05;
  static const double _last = 0.74;
  static const double _fadeStart = 0.9;

  double arrival(int i) => _first + (_last - _first) * i / (count - 1);

  /// 1 during the cycle, easing to 0 at the very end (seamless loop).
  double get reset => 1 - Curves.easeInOut.transform(((t - _fadeStart) / (1 - _fadeStart)).clamp(0.0, 1.0));

  /// 0 → 1 as the step lights up.
  double activation(int i) => Curves.easeOutCubic.transform(((t - arrival(i)) / 0.05).clamp(0.0, 1.0)) * reset;

  /// 0 → 1 ripple wave right after arrival (0 when idle).
  double ripple(int i) {
    final q = (t - arrival(i)) / 0.14;
    return q <= 0 || q >= 1 ? 0 : q;
  }

  /// Fill of the connector below step i (0 … 1), eased like flowing water.
  double flow(int i) {
    final from = arrival(i) + 0.02;
    final to = arrival(i + 1);
    return Curves.easeInOutCubic.transform(((t - from) / (to - from)).clamp(0.0, 1.0)) * reset;
  }
}

class _FormulaStepRow extends StatelessWidget {
  const _FormulaStepRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isLast,
    required this.isReward,
    required this.activation,
    required this.ripple,
    required this.flow,
    this.trailing,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool isReward;

  /// 0 = upcoming, 1 = reached (lit).
  final double activation;

  /// 0…1 ripple progress right after the step is reached.
  final double ripple;

  /// 0…1 fill of the connector towards the next step.
  final double flow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Upcoming rows rest a little dimmed; reached rows are fully bright.
    final textOpacity = 0.55 + 0.45 * activation;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                _StepNode(emoji: emoji, activation: activation, ripple: ripple, burst: isReward ? ripple : 0),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: CustomPaint(painter: _FlowConnectorPainter(flow), child: const SizedBox(width: 14)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Opacity(
              opacity: textOpacity,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: Color.lerp(AppColors.ink, AppColors.primaryInk, isReward ? activation : 0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(top: 10), child: trailing),
        ],
      ),
    );
  }
}

/// Circle with the step emoji: white when upcoming; when reached, sky
/// "water" rises inside it with a gentle pop, and a ripple ring spreads
/// (sparkles burst on the reward step).
class _StepNode extends StatelessWidget {
  const _StepNode({required this.emoji, required this.activation, required this.ripple, required this.burst});

  final String emoji;
  final double activation;
  final double ripple;
  final double burst;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final pop = 1 + 0.14 * math.sin(activation * math.pi); // 1 → 1.14 → 1
    return SizedBox.square(
      dimension: 52,
      child: CustomPaint(
        painter: _NodeEffectsPainter(ripple: ripple, burst: burst),
        child: Center(
          child: Transform.scale(
            scale: pop,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16 + 0.4 * activation),
                    blurRadius: 10 + 12 * activation,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: activation,
                          widthFactor: 1,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFA8DDF8), Color(0xFF5AAFE6)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(emoji, style: const TextStyle(fontSize: 21)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeEffectsPainter extends CustomPainter {
  _NodeEffectsPainter({required this.ripple, required this.burst});

  final double ripple;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (ripple > 0) {
      final t = Curves.easeOutCubic.transform(ripple);
      canvas.drawCircle(
        center,
        22 + 16 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - t) + 0.4
          ..color = AppColors.primary.withValues(alpha: 0.7 * (1 - t)),
      );
    }
    if (burst > 0) {
      // Reward: six little sparkles fly out and fade.
      final t = Curves.easeOutCubic.transform(burst);
      for (var i = 0; i < 6; i++) {
        final angle = -math.pi / 2 + i * math.pi / 3;
        final position = center + Offset(math.cos(angle), math.sin(angle)) * (24 + 20 * t);
        final color = i.isEven ? const Color(0xFFFFC857) : AppColors.primary;
        canvas.drawCircle(position, 3.2 * (1 - t) + 0.8, Paint()..color = color.withValues(alpha: 1 - t));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NodeEffectsPainter oldDelegate) =>
      oldDelegate.ripple != ripple || oldDelegate.burst != burst;
}

/// The connector is a soft track that fills with sky "water" from the top;
/// a glowing drop rides the front of the flow.
class _FlowConnectorPainter extends CustomPainter {
  _FlowConnectorPainter(this.flow);

  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5, 0, 3, size.height), const Radius.circular(2)),
      Paint()..color = AppColors.primary.withValues(alpha: 0.16),
    );
    if (flow <= 0) return;

    final filled = size.height * flow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5, 0, 3, filled), const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF89CFF0), Color(0xFF3F97DA)],
        ).createShader(Offset.zero & size),
    );
    if (flow < 1) {
      final head = Offset(x, filled);
      canvas
        ..drawCircle(
          head,
          7,
          Paint()
            ..color = AppColors.primary.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        )
        ..drawCircle(head, 3.6, Paint()..color = Colors.white)
        ..drawCircle(head, 2.2, Paint()..color = const Color(0xFF3F97DA));
    }
  }

  @override
  bool shouldRepaint(covariant _FlowConnectorPainter oldDelegate) => oldDelegate.flow != flow;
}

/// Overlapping mini app icons ("TikTok, Instagram, +2").
class _AppStack extends StatelessWidget {
  const _AppStack({required this.apps});

  final List<BlockableAppModel> apps;

  @override
  Widget build(BuildContext context) {
    final visible = apps.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 26.0 + (visible.length - 1) * 16,
      height: 26,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            PositionedDirectional(
              start: i * 16.0,
              child: BlockableAppIconWidget(app: visible[i], size: 26),
            ),
        ],
      ),
    );
  }
}

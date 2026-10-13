import 'package:flutter/material.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';

/// "Where your idea goes": idea → most-requested first → shipped in an update.
/// A glowing comet travels along the path and lights each stop as it passes;
/// the rocket hops when the idea arrives. Loops every 3.6 s.
class FeedbackIdeaJourneyWidget extends StatefulWidget {
  const FeedbackIdeaJourneyWidget({super.key});

  @override
  State<FeedbackIdeaJourneyWidget> createState() => _FeedbackIdeaJourneyWidgetState();
}

class _FeedbackIdeaJourneyWidgetState extends State<FeedbackIdeaJourneyWidget> with SingleTickerProviderStateMixin {
  static const double _nodeSize = 40;

  static const List<(IconData, String)> _stops = [
    (Icons.lightbulb_rounded, 'feedback_journey_idea'),
    (Icons.how_to_vote_rounded, 'feedback_journey_votes'),
    (Icons.rocket_launch_rounded, 'feedback_journey_ship'),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.8; // every stop lit, no comet
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Travel takes the first 72 % of the loop; the lit path then fades out.
  double get _progress => Curves.easeInOutCubic.transform((_controller.value / 0.72).clamp(0.0, 1.0));
  double get _fade => 1 - ((_controller.value - 0.86) / 0.14).clamp(0.0, 1.0);

  /// 0 → 1 as the comet reaches stop [index].
  double _litFor(int index) {
    final at = index / (_stops.length - 1);
    return ((_progress - at + 0.06) / 0.06).clamp(0.0, 1.0) * _fade;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 14, AppSpacing.xs, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final column = constraints.maxWidth / _stops.length;
          double centerX(int index) => isRtl ? constraints.maxWidth - column * (index + 0.5) : column * (index + 0.5);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _nodeSize,
                  child: CustomPaint(
                    painter: _CometPathPainter(
                      start: Offset(centerX(0), _nodeSize / 2),
                      end: Offset(centerX(_stops.length - 1), _nodeSize / 2),
                      progress: _progress,
                      fade: _fade,
                      gap: _nodeSize / 2 + 4,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, (icon, labelKey)) in _stops.indexed)
                      Expanded(
                        child: _JourneyStop(
                          icon: icon,
                          label: context.tr(labelKey),
                          lit: _litFor(index),
                          // The rocket hops as the idea lands on it.
                          hop: index == _stops.length - 1 ? _litFor(index) * (1 - _litFor(index)) * 4 : 0,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({required this.icon, required this.label, required this.lit, required this.hop});

  final IconData icon;
  final String label;
  final double lit;
  final double hop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.translate(
          offset: Offset(0, -hop * 6),
          child: Container(
            width: _FeedbackIdeaJourneyWidgetState._nodeSize,
            height: _FeedbackIdeaJourneyWidgetState._nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(const Color(0xFF26456F), Colors.white, lit),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25 + lit * 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.7 * lit), blurRadius: 18, spreadRadius: -2),
              ],
            ),
            child: Icon(
              icon,
              size: 19,
              color: Color.lerp(Colors.white.withValues(alpha: 0.7), AppColors.primaryInk, lit),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11.5,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6 + lit * 0.35),
          ),
        ),
      ],
    );
  }
}

/// Dotted track between the stops + the glowing comet with its fading tail.
class _CometPathPainter extends CustomPainter {
  _CometPathPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.fade,
    required this.gap,
  });

  final Offset start;
  final Offset end;
  final double progress;
  final double fade;

  /// Distance kept clear around the first and last stop.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final direction = (end - start) / (end - start).distance;
    final from = start + direction * gap;
    final to = end - direction * gap;
    final length = (to - from).distance;

    // Dotted track.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (var d = 0.0; d <= length; d += 7) {
      canvas.drawCircle(from + direction * d, 1.2, dot);
    }

    // Lit trail behind the comet.
    final head = Offset.lerp(start, end, progress)!;
    final headDistance = ((head - from).dx * direction.dx).clamp(0.0, length);
    if (headDistance > 0) {
      final tail = from + direction * headDistance;
      canvas.drawLine(
        from,
        tail,
        Paint()
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            // Dim at the first stop, bright at the comet (mirrored in RTL).
            begin: direction.dx > 0 ? Alignment.centerLeft : Alignment.centerRight,
            end: direction.dx > 0 ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              AppColors.primary.withValues(alpha: 0.15 * fade),
              const Color(0xFFD9F1FF).withValues(alpha: 0.9 * fade),
            ],
          ).createShader(Rect.fromPoints(from, tail.translate(0.1, 0.1))),
      );
    }

    // Comet head (hidden while it sits on a stop's circle).
    if (progress > 0 && progress < 1) {
      canvas
        ..drawCircle(
          head,
          10,
          Paint()
            ..shader = RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.85 * fade), AppColors.primary.withValues(alpha: 0)],
            ).createShader(Rect.fromCircle(center: head, radius: 10)),
        )
        ..drawCircle(head, 2.6, Paint()..color = Colors.white.withValues(alpha: fade));
    }
  }

  @override
  bool shouldRepaint(covariant _CometPathPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.fade != fade || oldDelegate.start != start;
}

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/sinkly_logo_mark_painter.dart';

/// Screen 14 hero: a lock-screen preview of the exact reminder the user will
/// get before the trial ends.
///
/// * The phone rises in, glowing on a soft sky aura with slowly turning light
///   rays behind it.
/// * Two light "comets" orbit the bezel continuously (glowing tails), while
///   the frame halo breathes.
/// * The Sinkly notification drops out of the Dynamic Island with a spring
///   (+ a light haptic), then floats gently.
/// * The phone dissolves into the background at the bottom.
class TrialReminderPhoneWidget extends StatefulWidget {
  const TrialReminderPhoneWidget({super.key});

  @override
  State<TrialReminderPhoneWidget> createState() => _TrialReminderPhoneWidgetState();
}

class _TrialReminderPhoneWidgetState extends State<TrialReminderPhoneWidget> with TickerProviderStateMixin {
  static const double _phoneWidth = 268;
  static const double _phoneHeight = 560; // only the top ~60% is ever visible
  static const double _phoneTop = 18;
  static const double _glowPad = 24;
  static const double _canvasWidth = 340;
  static const double _canvasHeight = 420;

  /// Comets orbiting the bezel.
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    ..repeat();

  /// Slow ambient clock (rays rotation, halo breathing).
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 14))
    ..repeat();

  @override
  void initState() {
    super.initState();
    // Haptic tick the moment the notification lands.
    Future<void>.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) AppFunctions.lightHaptic();
    });
  }

  @override
  void dispose() {
    _orbit.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    // The trial ends 3 days from today; the reminder arrives the day before.
    final trialEnd = today.add(const Duration(days: AppConstants.freeTrialDays));
    final reminderDay = trialEnd.subtract(const Duration(days: 1));
    final material = MaterialLocalizations.of(context);

    return SizedBox(
      width: _canvasWidth,
      height: _canvasHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Aura + fanning light rays behind the phone.
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _AuraPainter(_ambient))),
          ),
          // The phone: taller than what's shown, dissolving into the background
          // long before its bottom corners (no boxy edge). The padding keeps the
          // bezel glow inside the mask so it never gets clipped into a rectangle.
          Positioned(
            top: _phoneTop - _glowPad,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, 0.42, 0.9],
              ).createShader(rect),
              child: SizedBox(
                width: _phoneWidth + _glowPad * 2,
                height: _canvasHeight - _phoneTop + _glowPad,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: _glowPad,
                      top: _glowPad,
                      width: _phoneWidth,
                      height: _phoneHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _LockScreen(date: material.formatMediumDate(reminderDay))),
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _BezelPainter(orbit: _orbit, ambient: _ambient),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic, duration: 700.ms),
          ),
          // The notification (wider than the screen, like the real thing).
          Positioned(
            top: _phoneTop + 168,
            left: 4,
            right: 4,
            child:
                _NotificationCard(
                      title: context.tr('trial_notif_title'),
                      body: context.tr('trial_notif_body', {
                        'saved': context.tr('duration_hours_minutes', {'h': '4', 'm': '20'}),
                        'date': material.formatShortMonthDay(trialEnd),
                      }),
                      time: context.tr('trial_notif_now'),
                    )
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 220.ms)
                    .slideY(begin: -1.6, duration: 650.ms, curve: Curves.easeOutBack)
                    .scaleXY(begin: 0.55, duration: 650.ms, curve: Curves.easeOutBack)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -4, duration: 2400.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

/// Brand lock screen: sky → lavender wallpaper with soft blobs, Dynamic
/// Island, date and a big translucent clock.
class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFCFEBFB), Color(0xFF9FD3F4), Color(0xFF8EA6EC)],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              // Soft light blobs on the wallpaper.
              Positioned(top: -40, left: -30, child: _Blob(size: 170, color: Colors.white.withValues(alpha: 0.45))),
              Positioned(
                bottom: 30,
                right: -50,
                child: _Blob(size: 190, color: const Color(0xFFE6DEFF).withValues(alpha: 0.6)),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Dynamic Island.
                    Container(
                      width: 86,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xFF14192B), borderRadius: AppRadii.pillAll),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      date,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 15,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '9:41',
                        style: AppTextStyles.display.copyWith(
                          fontSize: 72,
                          height: 1.05,
                          letterSpacing: -2,
                          color: Colors.white.withValues(alpha: 0.95),
                          shadows: [Shadow(color: const Color(0xFF3F97DA).withValues(alpha: 0.35), blurRadius: 18)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.title, required this.body, required this.time});

  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F97DA).withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox.square(
              dimension: 38,
              child: CustomPaint(painter: SinklyLogoMarkPainter(background: SinklyLogoBackground.square)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 13.5, height: 1.25),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(time, style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft sky aura with slowly turning light rays (the "fan" behind the phone).
class _AuraPainter extends CustomPainter {
  _AuraPainter(this.ambient) : super(repaint: ambient);

  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final breathe = 0.92 + 0.08 * math.sin(ambient.value * 2 * math.pi * 2);

    canvas.drawCircle(
      center,
      size.width * 0.62 * breathe,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF89CFF0).withValues(alpha: 0.55),
            const Color(0xFFB9B4F8).withValues(alpha: 0.22),
            const Color(0xFFB9B4F8).withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.62)),
    );

    // Fanning rays, turning very slowly.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(ambient.value * 2 * math.pi * 0.25);
    final rayLength = size.height * 0.75;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final ray = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.07) * rayLength, math.sin(angle - 0.07) * rayLength)
        ..lineTo(math.cos(angle + 0.07) * rayLength, math.sin(angle + 0.07) * rayLength)
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: i.isEven ? 0.4 : 0.25),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: rayLength)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => false;
}

/// Bezel with a breathing halo and two light comets orbiting the frame.
class _BezelPainter extends CustomPainter {
  _BezelPainter({required this.orbit, required this.ambient}) : super(repaint: Listenable.merge([orbit, ambient]));

  final Animation<double> orbit;
  final Animation<double> ambient;

  static const double _radius = 46;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius((Offset.zero & size).deflate(3), const Radius.circular(_radius));
    final breathe = 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi * 3);

    // Breathing halo around the frame.
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFF89CFF0).withValues(alpha: 0.18 + 0.2 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Metal-glass bezel.
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFD5EBFA), Color(0xFFB7D9F2), Colors.white],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      frame.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    // Two comets on opposite sides of the loop.
    final metric = (Path()..addRRect(frame)).computeMetrics().first;
    _paintComet(canvas, metric, orbit.value, 1);
    _paintComet(canvas, metric, (orbit.value + 0.5) % 1, 0.65);
  }

  void _paintComet(Canvas canvas, PathMetric metric, double t, double strength) {
    final length = metric.length;
    final head = t * length;
    final tail = length * 0.2;
    const segments = 14;
    for (var i = 0; i < segments; i++) {
      final f0 = i / segments;
      final f1 = (i + 1) / segments;
      final start = head - tail * (1 - f0);
      final end = head - tail * (1 - f1);
      final path = _extractWrapped(metric, start, end);
      final alpha = math.pow(f1, 2).toDouble() * strength;
      canvas
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF5AAFE6).withValues(alpha: alpha * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(const Color(0xFF89CFF0), Colors.white, f1)!.withValues(alpha: alpha),
        );
    }
    // Bright head.
    final tangent = metric.getTangentForOffset(head % length);
    if (tangent != null) {
      canvas
        ..drawCircle(
          tangent.position,
          9,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.75 * strength)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawCircle(tangent.position, 2.6, Paint()..color = Colors.white.withValues(alpha: strength));
    }
  }

  /// Path segment that may wrap past the start of the closed loop.
  static Path _extractWrapped(PathMetric metric, double start, double end) {
    final length = metric.length;
    double wrap(double v) => ((v % length) + length) % length;
    final s = wrap(start);
    final e = wrap(end);
    if (s <= e) return metric.extractPath(s, e);
    return metric.extractPath(s, length)..addPath(metric.extractPath(0, e), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _BezelPainter oldDelegate) => false;
}

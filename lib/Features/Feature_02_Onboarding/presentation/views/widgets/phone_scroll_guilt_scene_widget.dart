import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/style.dart';
import 'heroine_character_painter.dart';
import 'heroine_character_widget.dart';
import 'rising_emoji_particles_widget.dart';

/// Screen 3 hero — a tiny story that mirrors the user's reality:
///   1. She scrolls happily; likes and hearts float out of the phone.
///   2. Behind her, the dish pile keeps growing, plate after plate.
///   3. The screen-time counter races up…
///   4. …her smile fades and a grey cloud of guilt forms above her head.
/// The loop restarts so the user can't look away from it.
class PhoneScrollGuiltSceneWidget extends StatefulWidget {
  const PhoneScrollGuiltSceneWidget({super.key});

  @override
  State<PhoneScrollGuiltSceneWidget> createState() => _PhoneScrollGuiltSceneWidgetState();
}

class _PhoneScrollGuiltSceneWidgetState extends State<PhoneScrollGuiltSceneWidget> {
  static const int _minPlates = 2;
  static const int _maxPlates = 9;
  static const Duration _plateInterval = Duration(milliseconds: 750);

  late final Timer _timer;
  int _plates = _minPlates;

  bool get _guilty => _plates >= 5;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_plateInterval, (_) {
      if (!mounted) return;
      setState(() => _plates = _plates >= _maxPlates ? _minPlates : _plates + 1);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const characterWidth = 150.0;
    final characterHeight = HeroineCharacterWidget.heightFor(characterWidth);
    // Screen-time "stolen" so far in this loop (in minutes).
    final minutes = 12 + (_plates - _minPlates) * 13;

    return SizedBox(
      width: 320,
      height: characterHeight + 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Counter + growing pile of dirty dishes (reading-start side).
          PositionedDirectional(start: 4, bottom: 6, child: _CounterWithPile(plates: _plates)),
          // Heroine scrolling.
          PositionedDirectional(
            end: 14,
            bottom: 0,
            child: HeroineCharacterWidget(
              width: characterWidth,
              pose: _guilty ? HeroinePose.scrollGuilty : HeroinePose.scroll,
              motion: HeroineMotion.scroll,
              prop: HeroineProp.phone,
            ),
          ),
          // Likes & hearts escaping the phone (dopamine hits).
          PositionedDirectional(
            end: 76,
            top: characterHeight * 0.38,
            child: const RisingEmojiParticlesWidget(emojis: ['❤️', '👍', '💬', '❤️', '🔥']),
          ),
          // Guilt cloud above her head.
          PositionedDirectional(
            end: 52,
            top: -6,
            child: AnimatedOpacity(
              opacity: _guilty ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: AnimatedScale(
                scale: _guilty ? 1 : 0.6,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                child: const _GuiltCloud(),
              ),
            ),
          ),
          // Screen-time counter racing up.
          PositionedDirectional(
            start: 10,
            top: 8,
            child: _ScreenTimeChip(minutes: minutes, alarming: _guilty),
          ),
        ],
      ),
    );
  }
}

class _CounterWithPile extends StatelessWidget {
  const _CounterWithPile({required this.plates});

  final int plates;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 170,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Counter.
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: AppShadows.soft,
            ),
          ),
          for (var i = 0; i < plates; i++)
            Positioned(
              bottom: 48 + i * 10.0,
              child: Transform.translate(
                offset: Offset(((i * 37) % 11 - 5).toDouble(), 0),
                child: _DirtyPlate(index: i)
                    .animate(key: ValueKey('pile$i'))
                    .moveY(begin: -70, end: 0, duration: 480.ms, curve: Curves.bounceOut)
                    .fadeIn(duration: 120.ms),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirtyPlate extends StatelessWidget {
  const _DirtyPlate({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const smudges = [Color(0xFFB98B5E), Color(0xFF9CB36B), Color(0xFFD98C6C)];
    return Container(
      width: 92.0 - (index % 3) * 6,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E2EE), width: 1.8),
        boxShadow: AppShadows.soft,
      ),
      alignment: AlignmentDirectional(-0.4 + (index % 3) * 0.3, 0),
      child: Container(
        width: 12,
        height: 6,
        decoration: BoxDecoration(
          color: smudges[index % 3].withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _GuiltCloud extends StatefulWidget {
  const _GuiltCloud();

  @override
  State<_GuiltCloud> createState() => _GuiltCloudState();
}

class _GuiltCloudState extends State<_GuiltCloud> with SingleTickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _rain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(size: const Size(96, 72), painter: _CloudPainter(_rain)),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB7BFD3), Color(0xFF8E98B3)],
      ).createShader(Offset.zero & size);
    canvas
      ..drawCircle(const Offset(30, 28), 16, cloud)
      ..drawCircle(const Offset(52, 20), 20, cloud)
      ..drawCircle(const Offset(72, 30), 14, cloud)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 26, 70, 18), const Radius.circular(9)), cloud);
    final drop = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryDeep.withValues(alpha: 0.75);
    for (var i = 0; i < 5; i++) {
      final p = (animation.value + i / 5) % 1.0;
      final x = 26.0 + i * 11;
      final y = 46 + p * 22;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2, y + 6),
        drop..color = AppColors.primaryDeep.withValues(alpha: 0.8 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => false;
}

class _ScreenTimeChip extends StatelessWidget {
  const _ScreenTimeChip({required this.minutes, required this.alarming});

  final int minutes;
  final bool alarming;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: alarming ? AppColors.dangerSoft : Colors.white,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 15, color: alarming ? AppColors.danger : AppColors.inkSoft),
          const SizedBox(width: 5),
          TweenAnimationBuilder<int>(
            tween: IntTween(end: minutes),
            duration: const Duration(milliseconds: 650),
            builder: (context, value, _) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${value ~/ 60}h ${(value % 60).toString().padLeft(2, '0')}m',
                style: AppTextStyles.label.copyWith(
                  letterSpacing: 0,
                  fontSize: 12.5,
                  color: alarming ? AppColors.danger : AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

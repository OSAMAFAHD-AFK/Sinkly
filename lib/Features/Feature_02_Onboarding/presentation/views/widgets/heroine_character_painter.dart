import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/utils/style.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  THE SINKLY HEROINE — a small 2D character rig drawn entirely in code.
///
///  • Pose  = where the hands are + facial expression (+ lean / head tilt).
///  • Arms  = two-bone IK (shoulder → elbow → hand), elbows always bend
///            outward, so any hand target produces a natural arm.
///  • Life  = procedural layers on top of the pose: breathing, blinking,
///            ponytail spring, and a per-scene "motion" (wave, scroll,
///            scrub, cheer, stress, yawn, cherish).
///  • Poses blend with an overshooting ease, motions cross-fade, so every
///    change of emotion is fluid instead of a hard swap.
///
///  Character space is 240 × 300 (feet at the bottom); the painter scales it.
/// ─────────────────────────────────────────────────────────────────────────

enum HeroineProp { none, phone, heart, plate }

enum HeroineMotion { idle, wave, scroll, scrub, cheer, stress, yawn, cherish, beckon, jumpJoy, clap, bounce }

@immutable
class HeroinePose {
  const HeroinePose({
    required this.leftHand,
    required this.rightHand,
    this.lean = 0,
    this.headTilt = 0,
    this.lookDown = 0,
    this.eyeOpen = 1,
    this.happyEyes = 0,
    this.smile = 0.4,
    this.mouthOpen = 0,
    this.brows = 0,
    this.blush = 0.35,
    this.sweat = 0,
    this.bodyY = 0,
  });

  final Offset leftHand;
  final Offset rightHand;
  final double lean;
  final double headTilt;
  final double lookDown;
  final double eyeOpen;

  /// 0 = round eyes, 1 = joyful "^ ^" eyes.
  final double happyEyes;

  /// -1 frown … 1 big smile.
  final double smile;
  final double mouthOpen;

  /// -1 sad (inner ends up) … 1 determined.
  final double brows;
  final double blush;
  final double sweat;
  final double bodyY;

  static const Offset _idleLeft = Offset(74, 206);
  static const Offset _idleRight = Offset(166, 206);

  // ── Library of poses (each one is an emotion + a gesture) ──────────────
  static const idle = HeroinePose(leftHand: _idleLeft, rightHand: _idleRight, smile: 0.45, headTilt: 0.03);
  static const curious = HeroinePose(
    leftHand: _idleLeft,
    rightHand: _idleRight,
    smile: 0.2,
    headTilt: -0.1,
    brows: 0.25,
  );
  static const meh = HeroinePose(leftHand: _idleLeft, rightHand: _idleRight, smile: 0.02, brows: -0.2, blush: 0.15);
  static const worried = HeroinePose(
    leftHand: Offset(82, 204),
    rightHand: Offset(158, 204),
    smile: -0.45,
    brows: -0.85,
    sweat: 1,
    headTilt: -0.05,
    blush: 0.1,
  );
  static const overwhelmed = HeroinePose(
    leftHand: Offset(86, 62),
    rightHand: Offset(154, 62),
    smile: -0.75,
    mouthOpen: 0.45,
    brows: -1,
    sweat: 1,
    eyeOpen: 1.15,
    blush: 0.05,
  );
  static const wave = HeroinePose(
    leftHand: _idleLeft,
    rightHand: Offset(180, 50),
    smile: 0.75,
    mouthOpen: 0.3,
    headTilt: 0.08,
    blush: 0.5,
  );
  static const waveJoy = HeroinePose(
    leftHand: _idleLeft,
    rightHand: Offset(180, 50),
    smile: 1,
    mouthOpen: 0.5,
    happyEyes: 1,
    headTilt: 0.1,
    blush: 0.85,
  );
  static const scroll = HeroinePose(
    leftHand: Offset(110, 160),
    rightHand: Offset(130, 160),
    lookDown: 1,
    headTilt: 0.1,
    smile: 0.1,
    brows: -0.1,
    blush: 0.1,
  );
  static const scrollGuilty = HeroinePose(
    leftHand: Offset(110, 162),
    rightHand: Offset(130, 162),
    lookDown: 1,
    headTilt: 0.14,
    smile: -0.5,
    brows: -0.8,
    blush: 0.05,
  );
  static const washSad = HeroinePose(
    leftHand: Offset(98, 198),
    rightHand: Offset(142, 198),
    lookDown: 0.8,
    smile: -0.4,
    brows: -0.75,
    blush: 0.08,
    headTilt: -0.04,
  );
  static const washJoy = HeroinePose(
    leftHand: Offset(98, 198),
    rightHand: Offset(142, 198),
    lookDown: 0.25,
    smile: 0.95,
    mouthOpen: 0.25,
    happyEyes: 1,
    blush: 0.75,
    headTilt: 0.07,
  );
  static const sleepy = HeroinePose(
    leftHand: _idleLeft,
    rightHand: _idleRight,
    eyeOpen: 0.45,
    smile: 0,
    brows: -0.25,
    headTilt: -0.12,
    blush: 0.2,
  );
  static const cheer = HeroinePose(
    leftHand: Offset(56, 36),
    rightHand: Offset(184, 36),
    happyEyes: 1,
    smile: 1,
    mouthOpen: 0.65,
    blush: 0.85,
  );
  static const cherish = HeroinePose(
    leftHand: Offset(102, 150),
    rightHand: Offset(138, 150),
    headTilt: 0.1,
    smile: 0.6,
    blush: 0.7,
  );
  static const cherishJoy = HeroinePose(
    leftHand: Offset(100, 146),
    rightHand: Offset(140, 146),
    headTilt: 0.12,
    smile: 1,
    mouthOpen: 0.35,
    happyEyes: 1,
    blush: 1,
  );

  // ── Paywall: persuasion poses ───────────────────────────────────────────
  // Presenting hand sits out at waist height: the elbow rests by her side and
  // the forearm opens toward the plans (an open-palm "here you go").

  /// Confident hand-on-hip, the other hand presenting the offer below her.
  static const present = HeroinePose(
    leftHand: Offset(96, 182),
    rightHand: Offset(208, 170),
    headTilt: 0.1,
    lean: 0.03,
    smile: 0.9,
    mouthOpen: 0.28,
    brows: 0.2,
    blush: 0.6,
  );

  /// Delighted (the best-value plan is selected).
  static const presentJoy = HeroinePose(
    leftHand: Offset(96, 182),
    rightHand: Offset(210, 164),
    headTilt: 0.12,
    lean: 0.04,
    smile: 1,
    mouthOpen: 0.45,
    happyEyes: 1,
    blush: 0.9,
  );

  /// Still happy, just calmer (monthly selected): friendly hand-on-hip,
  /// presenting hand open toward the plans.
  static const encourage = HeroinePose(
    leftHand: Offset(96, 182),
    rightHand: Offset(206, 174),
    headTilt: -0.08,
    smile: 0.8,
    mouthOpen: 0.2,
    happyEyes: 0.35,
    brows: 0.25,
    blush: 0.55,
  );

  /// Pure joy (annual picked): both arms flung up in a wide "V".
  static const joyJump = HeroinePose(
    leftHand: Offset(50, 42),
    rightHand: Offset(190, 42),
    happyEyes: 1,
    smile: 1,
    mouthOpen: 0.7,
    blush: 1,
  );

  /// Delighted & touched after the joy burst: hands clasped under her chin.
  static const adore = HeroinePose(
    leftHand: Offset(110, 128),
    rightHand: Offset(130, 128),
    headTilt: 0.13,
    happyEyes: 1,
    smile: 1,
    mouthOpen: 0.25,
    blush: 1,
  );

  /// Cheerful applause (monthly picked): hands in front of her chest.
  static const clapHappy = HeroinePose(
    leftHand: Offset(104, 150),
    rightHand: Offset(136, 150),
    headTilt: -0.06,
    happyEyes: 0.7,
    smile: 0.9,
    mouthOpen: 0.4,
    blush: 0.7,
  );

  HeroinePose copyWith({
    Offset? leftHand,
    Offset? rightHand,
    double? lean,
    double? headTilt,
    double? eyeOpen,
    double? mouthOpen,
    double? bodyY,
  }) => HeroinePose(
    leftHand: leftHand ?? this.leftHand,
    rightHand: rightHand ?? this.rightHand,
    lean: lean ?? this.lean,
    headTilt: headTilt ?? this.headTilt,
    lookDown: lookDown,
    eyeOpen: eyeOpen ?? this.eyeOpen,
    happyEyes: happyEyes,
    smile: smile,
    mouthOpen: mouthOpen ?? this.mouthOpen,
    brows: brows,
    blush: blush,
    sweat: sweat,
    bodyY: bodyY ?? this.bodyY,
  );

  static HeroinePose lerp(HeroinePose a, HeroinePose b, double t) => HeroinePose(
    leftHand: Offset.lerp(a.leftHand, b.leftHand, t)!,
    rightHand: Offset.lerp(a.rightHand, b.rightHand, t)!,
    lean: lerpDouble(a.lean, b.lean, t)!,
    headTilt: lerpDouble(a.headTilt, b.headTilt, t)!,
    lookDown: lerpDouble(a.lookDown, b.lookDown, t)!,
    eyeOpen: lerpDouble(a.eyeOpen, b.eyeOpen, t)!,
    happyEyes: lerpDouble(a.happyEyes, b.happyEyes, t)!,
    smile: lerpDouble(a.smile, b.smile, t)!,
    mouthOpen: lerpDouble(a.mouthOpen, b.mouthOpen, t)!,
    brows: lerpDouble(a.brows, b.brows, t)!,
    blush: lerpDouble(a.blush, b.blush, t)!,
    sweat: lerpDouble(a.sweat, b.sweat, t)!,
    bodyY: lerpDouble(a.bodyY, b.bodyY, t)!,
  );
}

/// Mutable animation state shared by the widget (which ticks it) and the
/// painter (which only reads it). Notifies once per frame.
class HeroineRig extends ChangeNotifier {
  HeroineRig({required HeroinePose pose, required this.motion, required this.prop})
    : _from = pose,
      _to = pose,
      _previousMotion = motion;

  double time = 0;
  HeroineMotion motion;
  HeroineProp prop;

  /// Extra scale for the held prop (e.g. the heart growing while holding).
  double propScale = 1;

  HeroinePose _from;
  HeroinePose _to;
  double _poseStart = -10;
  HeroineMotion _previousMotion;
  double _motionStart = -10;

  static const double _poseDuration = 0.65;
  static const double _motionBlend = 0.5;

  HeroinePose get _basePose {
    final t = ((time - _poseStart) / _poseDuration).clamp(0.0, 1.0);
    return HeroinePose.lerp(_from, _to, Curves.easeOutBack.transform(t));
  }

  void setPose(HeroinePose pose) {
    if (identical(pose, _to)) return;
    _from = _basePose;
    _to = pose;
    _poseStart = time;
  }

  void setMotion(HeroineMotion next) {
    if (next == motion) return;
    _previousMotion = motion;
    motion = next;
    _motionStart = time;
  }

  void tick(double seconds) {
    time = seconds;
    notifyListeners();
  }

  /// Pose for this frame: blended base pose + cross-faded procedural motion.
  HeroinePose get currentPose {
    final base = _basePose;
    final blend = Curves.easeInOut.transform(((time - _motionStart) / _motionBlend).clamp(0.0, 1.0));
    if (blend >= 1) return _applyMotion(base, motion, time);
    return HeroinePose.lerp(_applyMotion(base, _previousMotion, time), _applyMotion(base, motion, time), blend);
  }

  static HeroinePose _applyMotion(HeroinePose p, HeroineMotion motion, double t) {
    switch (motion) {
      case HeroineMotion.idle:
        return p.copyWith(lean: p.lean + math.sin(t * 0.9) * 0.015);
      case HeroineMotion.wave:
        return p.copyWith(
          rightHand: p.rightHand + Offset(math.sin(t * 9) * 13, -math.cos(t * 9).abs() * 4),
          headTilt: p.headTilt + math.sin(t * 4.5) * 0.03,
        );
      case HeroineMotion.scroll:
        // Thumb flicks every ~1.6 s: the phone lifts a hair and settles.
        final flick = math.max(0.0, math.sin(t * 2 * math.pi / 1.6)) * 2.2;
        return p.copyWith(
          leftHand: p.leftHand + Offset(0, -flick),
          rightHand: p.rightHand + Offset(0, -flick),
          headTilt: p.headTilt + math.sin(t * 1.1) * 0.02,
        );
      case HeroineMotion.scrub:
        final a = t * 8;
        return p.copyWith(
          leftHand: p.leftHand + Offset(math.cos(a) * 7, math.sin(a) * 3),
          rightHand: p.rightHand + Offset(math.cos(a + math.pi) * 7, math.sin(a + math.pi) * 3),
          lean: p.lean + math.sin(a) * 0.02,
        );
      case HeroineMotion.cheer:
        final hop = math.sin(t * 4.2).abs();
        return p.copyWith(
          bodyY: p.bodyY - hop * 12,
          leftHand: p.leftHand + Offset(math.sin(t * 8.4) * 5, math.cos(t * 8.4) * 4),
          rightHand: p.rightHand + Offset(-math.sin(t * 8.4) * 5, math.cos(t * 8.4) * 4),
        );
      case HeroineMotion.stress:
        final shake = math.sin(t * 7) * 0.06;
        return p.copyWith(
          headTilt: p.headTilt + shake,
          leftHand: p.leftHand + Offset(shake * 30, 0),
          rightHand: p.rightHand + Offset(shake * 30, 0),
        );
      case HeroineMotion.yawn:
        // A big yawn every 3.4 s: hand rises to cover the mouth.
        final phase = (t % 3.4) / 3.4;
        final bump = phase < 0.6 ? math.pow(math.sin(phase / 0.6 * math.pi), 2).toDouble() : 0.0;
        return p.copyWith(
          mouthOpen: 0.08 + 0.92 * bump,
          eyeOpen: (p.eyeOpen - 0.35 * bump).clamp(0.05, 2),
          leftHand: Offset.lerp(p.leftHand, const Offset(110, 100), bump),
          headTilt: p.headTilt - 0.08 * bump,
        );
      case HeroineMotion.beckon:
        // Presenting hand bounces invitingly toward the offer.
        final bounce = math.sin(t * 5.2);
        return p.copyWith(
          rightHand: p.rightHand + Offset(bounce * 5, -bounce.abs() * 7),
          lean: p.lean + math.sin(t * 1.3) * 0.02,
          headTilt: p.headTilt + math.sin(t * 2.6) * 0.03,
        );
      case HeroineMotion.cherish:
        return p.copyWith(lean: p.lean + math.sin(t * 1.6) * 0.04, headTilt: p.headTilt + math.sin(t * 1.6) * 0.05);
      case HeroineMotion.jumpJoy:
        // Springy hops (~0.5 s each): arms stretch higher at the apex and
        // swing open/closed like "yaaay!", head bobbing with the rhythm.
        final hop = math.sin(t * 6.2).abs();
        final swing = math.sin(t * 12.4) * 4;
        return p.copyWith(
          bodyY: p.bodyY - hop * 18,
          leftHand: p.leftHand + Offset(-swing, -hop * 6),
          rightHand: p.rightHand + Offset(swing, -hop * 6),
          headTilt: p.headTilt + math.sin(t * 6.2) * 0.06,
          mouthOpen: (p.mouthOpen + hop * 0.2).clamp(0.0, 1.0),
        );
      case HeroineMotion.clap:
        // Quick claps (hands meet ~2.4×/s) with a tiny bounce on each clap.
        final together = math.pow((math.sin(t * 2 * math.pi * 2.4) + 1) / 2, 2).toDouble();
        return p.copyWith(
          leftHand: p.leftHand + Offset(together * 12, -together * 2),
          rightHand: p.rightHand + Offset(-together * 12, -together * 2),
          bodyY: p.bodyY - together * 2.5,
          headTilt: p.headTilt + math.sin(t * 2.4) * 0.05,
        );
      case HeroineMotion.bounce:
        // Happy little bounce on her toes with a soft side-to-side sway.
        final lift = math.sin(t * 3.6).abs();
        return p.copyWith(
          bodyY: p.bodyY - lift * 4,
          lean: p.lean + math.sin(t * 1.8) * 0.035,
          headTilt: p.headTilt + math.sin(t * 1.8) * 0.05,
          leftHand: p.leftHand + Offset(0, -lift * 2),
          rightHand: p.rightHand + Offset(0, -lift * 2),
        );
    }
  }
}

class HeroinePainter extends CustomPainter {
  HeroinePainter(this.rig) : super(repaint: rig);

  final HeroineRig rig;

  static const double designWidth = 240;
  static const double designHeight = 300;

  static const Color _skin = Color(0xFFF8D2B6);
  static const Color _skinShade = Color(0xFFEDBB9C);
  static const Color _hair = Color(0xFF26305A);
  static const Color _top = Color(0xFFCFC8FF);
  static const Color _pants = Color(0xFF3D4B7A);
  static const Color _lips = Color(0xFFC2575F);
  static const Color _blushPink = Color(0xFFFF9BB3);

  static const double _upperArm = 48;
  static const double _forearm = 46;
  static const Offset _hip = Offset(120, 214);
  static const Offset _neck = Offset(120, 104);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = rig.currentPose;
    final t = rig.time;
    final breathe = math.sin(t * 2 * math.pi / 3.6);

    canvas.save();
    canvas.scale(size.width / designWidth);

    // Ground shadow stays on the floor while the body hops.
    final hop = (-pose.bodyY / 14).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 292), width: 104 - hop * 24, height: 14 - hop * 4),
      Paint()..color = AppColors.ink.withValues(alpha: 0.09 - hop * 0.03),
    );

    canvas.translate(0, pose.bodyY);

    final shoulderLift = breathe * 0.9;
    final leftShoulder = _rotateAround(Offset(88, 120 + shoulderLift), _hip, pose.lean);
    final rightShoulder = _rotateAround(Offset(152, 120 + shoulderLift), _hip, pose.lean);
    final headPivot = _rotateAround(_neck.translate(0, shoulderLift), _hip, pose.lean);
    final headRotation = pose.headTilt + pose.lean * 0.6;

    _drawPonytail(canvas, headPivot, headRotation, t, pose);
    _drawLegs(canvas);
    _drawBackHair(canvas, headPivot, headRotation);
    _drawTorso(canvas, pose, breathe);
    final leftElbow = _solveElbow(leftShoulder, pose.leftHand, -1);
    final rightElbow = _solveElbow(rightShoulder, pose.rightHand, 1);
    _drawArm(canvas, leftShoulder, leftElbow, pose.leftHand);
    _drawArm(canvas, rightShoulder, rightElbow, pose.rightHand);
    // The heart is held up in FRONT of the hands; other props sit behind them.
    final propInFront = rig.prop == HeroineProp.heart;
    if (!propInFront) _drawProp(canvas, pose, t);
    _drawHand(canvas, pose.leftHand);
    _drawHand(canvas, pose.rightHand);
    if (propInFront) _drawProp(canvas, pose, t);
    _drawHead(canvas, headPivot, headRotation, pose, t);

    canvas.restore();
  }

  // ── Body ────────────────────────────────────────────────────────────────
  void _drawLegs(Canvas canvas) {
    final pants = Paint()..color = _pants;
    canvas
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(98, 200, 20, 86), const Radius.circular(9)), pants)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(122, 200, 20, 86), const Radius.circular(9)), pants);
    for (final x in const [92.0, 120.0]) {
      final shoe = RRect.fromRectAndRadius(Rect.fromLTWH(x, 280, 28, 13), const Radius.circular(7));
      canvas
        ..drawRRect(shoe, Paint()..color = Colors.white)
        ..drawRRect(
          shoe,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.primary,
        );
    }
  }

  void _drawTorso(Canvas canvas, HeroinePose pose, double breathe) {
    canvas.save();
    canvas.translate(_hip.dx, _hip.dy);
    canvas.rotate(pose.lean);
    canvas.scale(1, 1 + breathe * 0.012);
    canvas.translate(-_hip.dx, -_hip.dy);

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(112, 94, 16, 24), const Radius.circular(6)),
      Paint()..color = _skinShade,
    );
    // Top.
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        82,
        110,
        158,
        218,
        topLeft: const Radius.circular(28),
        topRight: const Radius.circular(28),
        bottomLeft: const Radius.circular(14),
        bottomRight: const Radius.circular(14),
      ),
      Paint()..color = _top,
    );
    // V collar.
    canvas.drawPath(
      Path()
        ..moveTo(110, 110)
        ..lineTo(120, 124)
        ..lineTo(130, 110)
        ..close(),
      Paint()..color = _skinShade,
    );
    // Apron (brand sky) with bib, straps, pocket heart.
    final apron = Path()
      ..moveTo(102, 132)
      ..lineTo(138, 132)
      ..lineTo(140, 150)
      ..lineTo(148, 150)
      ..lineTo(152, 220)
      ..lineTo(88, 220)
      ..lineTo(92, 150)
      ..lineTo(100, 150)
      ..close();
    canvas.drawPath(apron, Paint()..color = AppColors.primary);
    canvas.drawPath(
      apron,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    final strap = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas
      ..drawLine(const Offset(104, 133), const Offset(97, 113), strap)
      ..drawLine(const Offset(136, 133), const Offset(143, 113), strap)
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(108, 172, 24, 18), const Radius.circular(5)),
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      )
      ..drawPath(_heartPath(const Offset(120, 181), 5), Paint()..color = Colors.white);
    canvas.restore();
  }

  void _drawArm(Canvas canvas, Offset shoulder, Offset elbow, Offset hand) {
    canvas
      ..drawLine(
        elbow,
        hand,
        Paint()
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = _skin,
      )
      ..drawLine(
        shoulder,
        Offset.lerp(shoulder, elbow, 0.62)!,
        Paint()
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..color = _top,
      );
    // Upper arm skin below the short sleeve.
    canvas.drawLine(
      Offset.lerp(shoulder, elbow, 0.62)!,
      elbow,
      Paint()
        ..strokeWidth = 12.5
        ..strokeCap = StrokeCap.round
        ..color = _skin,
    );
  }

  void _drawHand(Canvas canvas, Offset hand) {
    canvas.drawCircle(hand, 8.5, Paint()..color = _skin);
    canvas.drawCircle(hand.translate(-2, -2), 3, Paint()..color = Colors.white.withValues(alpha: 0.25));
  }

  // ── Head ────────────────────────────────────────────────────────────────
  void _drawBackHair(Canvas canvas, Offset pivot, double rotation) {
    canvas.save();
    _applyHeadTransform(canvas, pivot, rotation);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(80, 28, 80, 86), const Radius.circular(38)),
      Paint()..color = _hair,
    );
    canvas.restore();
  }

  void _drawPonytail(Canvas canvas, Offset pivot, double rotation, double t, HeroinePose pose) {
    canvas.save();
    _applyHeadTransform(canvas, pivot, rotation);
    // Spring-like sway: follows the head with a little lag + idle swing.
    final swing = math.sin(t * 2.3) * 0.22 - rotation * 0.8 + pose.bodyY * -0.01;
    const anchor = Offset(152, 38);
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(swing);
    final tail = Path()
      ..moveTo(-8, -2)
      ..cubicTo(34, -4, 48, 40, 32, 82)
      ..cubicTo(28, 56, 14, 30, -6, 18)
      ..close();
    canvas.drawPath(tail, Paint()..color = _hair);
    canvas.drawPath(
      Path()
        ..moveTo(6, 4)
        ..quadraticBezierTo(30, 22, 30, 52),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.2),
    );
    // Hair tie.
    canvas.drawCircle(const Offset(-2, 4), 5, Paint()..color = AppColors.primary);
    canvas.restore();
  }

  void _drawHead(Canvas canvas, Offset pivot, double rotation, HeroinePose pose, double t) {
    canvas.save();
    _applyHeadTransform(canvas, pivot, rotation);

    final skin = Paint()..color = _skin;
    canvas
      ..drawCircle(const Offset(87, 72), 7, skin)
      ..drawCircle(const Offset(153, 72), 7, skin)
      ..drawCircle(const Offset(120, 68), 34, skin);

    // Phone light on the face.
    if (rig.prop == HeroineProp.phone) {
      canvas.drawCircle(
        const Offset(120, 92),
        36,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.primary.withValues(alpha: 0.32), AppColors.primary.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: const Offset(120, 92), radius: 36)),
      );
    }

    // Cheeks.
    final blush = Paint()..color = _blushPink.withValues(alpha: (pose.blush * 0.55).clamp(0, 0.6));
    canvas
      ..drawOval(Rect.fromCenter(center: const Offset(100, 84), width: 13, height: 7), blush)
      ..drawOval(Rect.fromCenter(center: const Offset(140, 84), width: 13, height: 7), blush);

    _drawEyes(canvas, pose, t);
    _drawBrows(canvas, pose);
    _drawMouth(canvas, pose);

    // Bangs with a soft side part.
    final bangs = Path()
      ..moveTo(85, 70)
      ..cubicTo(80, 26, 150, 18, 157, 66)
      ..cubicTo(150, 50, 136, 42, 118, 46)
      ..cubicTo(108, 50, 98, 56, 85, 70)
      ..close();
    canvas.drawPath(bangs, Paint()..color = _hair);
    canvas.drawPath(
      Path()
        ..moveTo(100, 38)
        ..quadraticBezierTo(116, 30, 132, 34),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    if (pose.sweat > 0.02) _drawSweat(canvas, pose.sweat, t);
    canvas.restore();
  }

  void _drawEyes(Canvas canvas, HeroinePose pose, double t) {
    // Natural blink every ~3.7 s (skipped when the eyes are joyful arcs).
    final blinkPhase = (t % 3.7) / 3.7;
    final blink = blinkPhase < 0.04 ? 1 - math.sin(blinkPhase / 0.04 * math.pi) : 1.0;
    final open = (pose.eyeOpen * blink).clamp(0.08, 1.3);
    final dy = pose.lookDown * 3;
    final round = (1 - pose.happyEyes).clamp(0.0, 1.0);
    final joy = pose.happyEyes.clamp(0.0, 1.0);

    for (final x in const [107.0, 133.0]) {
      final center = Offset(x, 74 + dy);
      if (round > 0.01) {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 9, height: 12 * open),
          Paint()..color = _hair.withValues(alpha: round),
        );
        if (open > 0.5) {
          canvas.drawCircle(
            center.translate(-1.6, -2.6 * open),
            1.9,
            Paint()..color = Colors.white.withValues(alpha: round),
          );
        }
      }
      if (joy > 0.01) {
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - 6, center.dy + 2)
            ..quadraticBezierTo(center.dx, center.dy - 6, center.dx + 6, center.dy + 2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = _hair.withValues(alpha: joy),
        );
      }
    }
  }

  void _drawBrows(Canvas canvas, HeroinePose pose) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = _hair.withValues(alpha: 0.85);
    final inner = 62 + pose.brows * 3;
    final outer = 62 - pose.brows * 1.2;
    canvas
      ..drawLine(Offset(100, outer), Offset(113, inner), paint)
      ..drawLine(Offset(140, outer), Offset(127, inner), paint);
  }

  void _drawMouth(Canvas canvas, HeroinePose pose) {
    final y = 91 + pose.lookDown * 2;
    final k = pose.smile;
    final halfWidth = 7.5 + k.abs() * 1.5;
    if (pose.mouthOpen < 0.08) {
      canvas.drawPath(
        Path()
          ..moveTo(120 - halfWidth, y)
          ..quadraticBezierTo(120, y + k * 8, 120 + halfWidth, y),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = _lips,
      );
      return;
    }
    final open = pose.mouthOpen.clamp(0.0, 1.2);
    final mouth = Path()
      ..moveTo(120 - halfWidth, y)
      ..quadraticBezierTo(120, y + k * 3, 120 + halfWidth, y)
      ..quadraticBezierTo(120, y + k * 5 + open * 13, 120 - halfWidth, y)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFF8C3B4A));
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawCircle(Offset(120, y + 4 + open * 9), 6, Paint()..color = const Color(0xFFFF8FA3));
    canvas.restore();
  }

  void _drawSweat(Canvas canvas, double amount, double t) {
    final slide = (t % 2.2) / 2.2;
    final center = Offset(154, 50 + slide * 14);
    final drop = Path()
      ..moveTo(center.dx, center.dy - 8)
      ..quadraticBezierTo(center.dx + 6, center.dy, center.dx, center.dy + 4)
      ..quadraticBezierTo(center.dx - 6, center.dy, center.dx, center.dy - 8)
      ..close();
    final alpha = amount * (1 - slide * 0.6);
    canvas
      ..drawPath(drop, Paint()..color = AppColors.primary.withValues(alpha: alpha))
      ..drawCircle(center.translate(-1.5, -1), 1.3, Paint()..color = Colors.white.withValues(alpha: alpha));
  }

  // ── Props ───────────────────────────────────────────────────────────────
  void _drawProp(Canvas canvas, HeroinePose pose, double t) {
    final center = Offset.lerp(pose.leftHand, pose.rightHand, 0.5)!;
    switch (rig.prop) {
      case HeroineProp.none:
        return;
      case HeroineProp.phone:
        _drawPhone(canvas, center.translate(0, -12), t);
      case HeroineProp.heart:
        _drawHeart(canvas, center.translate(0, -16), rig.propScale, t);
      case HeroineProp.plate:
        final plate = Rect.fromCenter(center: center.translate(0, -8), width: 50, height: 15);
        canvas
          ..drawOval(plate, Paint()..color = Colors.white)
          ..drawOval(
            plate,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..color = const Color(0xFFD5E2EE),
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: pose.rightHand.translate(-4, -8), width: 18, height: 11),
              const Radius.circular(4),
            ),
            Paint()..color = const Color(0xFFFFC857),
          );
    }
  }

  void _drawPhone(Canvas canvas, Offset center, double t) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.06);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-15, -26, 30, 52), const Radius.circular(7));
    canvas.drawRRect(body, Paint()..color = AppColors.ink);
    final screen = RRect.fromRectAndRadius(const Rect.fromLTWH(-12.5, -22, 25, 44), const Radius.circular(5));
    canvas.drawRRect(
      screen,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE6F7), Color(0xFFE9E7FF)],
        ).createShader(screen.outerRect),
    );
    // Endless feed scrolling inside the screen.
    canvas.save();
    canvas.clipRRect(screen);
    for (var i = 0; i < 4; i++) {
      final y = -22 + ((t * 26 + i * 13) % 52) - 4;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-10, y, 20, 9), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        )
        ..drawCircle(Offset(-6, y + 4.5), 2.4, Paint()..color = const Color(0xFFFF8FB1));
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double scale, double t) {
    final pulse = 1 + math.sin(t * 5) * 0.04;
    final s = scale * pulse;
    final glow = (scale - 0.8).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      44 * s,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8FB1).withValues(alpha: 0.25 + glow * 0.4),
            const Color(0x00FF8FB1),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 44 * s)),
    );
    final heart = _heartPath(center, 20 * s);
    canvas.drawPath(
      heart,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA8C5), Color(0xFFFF5E8A)],
        ).createShader(Rect.fromCircle(center: center, radius: 21 * s)),
    );
    canvas.drawCircle(center.translate(-8 * s, -7 * s), 4 * s, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  void _applyHeadTransform(Canvas canvas, Offset pivot, double rotation) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(rotation);
    canvas.translate(-_neck.dx, -_neck.dy);
  }

  static Offset _rotateAround(Offset point, Offset pivot, double angle) {
    if (angle == 0) return point;
    final dx = point.dx - pivot.dx;
    final dy = point.dy - pivot.dy;
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(pivot.dx + dx * c - dy * s, pivot.dy + dx * s + dy * c);
  }

  /// Two-bone IK. [side] = -1 for the left arm, +1 for the right arm.
  /// Of the two possible elbows, the one that hangs LOWER (gravity) and more
  /// OUTWARD wins: raised hands keep the elbow out to the side, while a hand
  /// held out at waist height keeps the elbow down by the body instead of
  /// popping up into a "broken wing".
  static Offset _solveElbow(Offset shoulder, Offset hand, int side) {
    final delta = hand - shoulder;
    final rawDistance = delta.distance;
    if (rawDistance < 0.001) return shoulder.translate(side * _upperArm, 0);
    final distance = rawDistance.clamp((_upperArm - _forearm).abs() + 0.5, _upperArm + _forearm - 0.5);
    final direction = delta / rawDistance;
    final a = (_upperArm * _upperArm - _forearm * _forearm + distance * distance) / (2 * distance);
    final h = math.sqrt(math.max(0, _upperArm * _upperArm - a * a));
    final base = shoulder + direction * a;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final first = base + perpendicular * h;
    final second = base - perpendicular * h;
    double score(Offset elbow) => (elbow.dx - shoulder.dx) * side * 0.5 + (elbow.dy - shoulder.dy);
    return score(first) >= score(second) ? first : second;
  }

  static Path _heartPath(Offset center, double size) {
    return Path()
      ..moveTo(center.dx, center.dy + size * 0.9)
      ..cubicTo(
        center.dx - size * 1.3,
        center.dy + size * 0.1,
        center.dx - size * 0.8,
        center.dy - size * 0.95,
        center.dx,
        center.dy - size * 0.35,
      )
      ..cubicTo(
        center.dx + size * 0.8,
        center.dy - size * 0.95,
        center.dx + size * 1.3,
        center.dy + size * 0.1,
        center.dx,
        center.dy + size * 0.9,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant HeroinePainter oldDelegate) => oldDelegate.rig != rig;
}

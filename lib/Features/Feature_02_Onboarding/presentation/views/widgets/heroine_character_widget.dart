import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/utils/app_localizations.dart';
import 'heroine_character_painter.dart';

/// Animated Sinkly heroine. Change [pose], [motion] or [prop] and she blends
/// into the new emotion/gesture smoothly. Mirrors herself in RTL.
///
/// [propScale] can be driven live (e.g. by the hold-to-commit progress) to
/// grow the held heart without rebuilding the widget tree.
class HeroineCharacterWidget extends StatefulWidget {
  const HeroineCharacterWidget({
    super.key,
    required this.pose,
    this.motion = HeroineMotion.idle,
    this.prop = HeroineProp.none,
    this.propScale,
    this.width = 180,
  });

  final HeroinePose pose;
  final HeroineMotion motion;
  final HeroineProp prop;
  final ValueListenable<double>? propScale;
  final double width;

  /// Height for a given width (character space is 240 × 300).
  static double heightFor(double width) => width * HeroinePainter.designHeight / HeroinePainter.designWidth;

  @override
  State<HeroineCharacterWidget> createState() => _HeroineCharacterWidgetState();
}

class _HeroineCharacterWidgetState extends State<HeroineCharacterWidget> with SingleTickerProviderStateMixin {
  late final HeroineRig _rig = HeroineRig(pose: widget.pose, motion: widget.motion, prop: widget.prop);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _syncPropScale();
    widget.propScale?.addListener(_syncPropScale);
    _ticker = createTicker((elapsed) => _rig.tick(elapsed.inMicroseconds / Duration.microsecondsPerSecond))..start();
  }

  void _syncPropScale() => _rig.propScale = widget.propScale?.value ?? 1;

  @override
  void didUpdateWidget(covariant HeroineCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rig
      ..setPose(widget.pose)
      ..setMotion(widget.motion)
      ..prop = widget.prop;
    if (oldWidget.propScale != widget.propScale) {
      oldWidget.propScale?.removeListener(_syncPropScale);
      widget.propScale?.addListener(_syncPropScale);
      _syncPropScale();
    }
  }

  @override
  void dispose() {
    widget.propScale?.removeListener(_syncPropScale);
    _ticker.dispose();
    _rig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.width,
          height: HeroineCharacterWidget.heightFor(widget.width),
          child: Transform.flip(
            flipX: context.isRtl,
            child: CustomPaint(painter: HeroinePainter(_rig)),
          ),
        ),
      ),
    );
  }
}

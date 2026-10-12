import 'package:flutter/material.dart';

/// Hosts a code-drawn illustration/scene that was composed at a fixed design
/// size and keeps it intact on every phone:
///
/// * the scene is laid out at its natural size (never wider than
///   [maxDesignWidth]), so its internal composition never changes;
/// * it is then scaled down **uniformly** when the available width is smaller
///   (compact phones, Android "large display size") or when it would take more
///   than [maxHeightFraction] of the screen height (short phones, iPhone SE),
///   so the question/options below stay visible.
///
/// It never scales up, so large phones show the scene at 1:1.
class AdaptiveSceneBoxWidget extends StatelessWidget {
  const AdaptiveSceneBoxWidget({
    super.key,
    required this.child,
    this.maxDesignWidth = 340,
    this.maxHeightFraction = 0.36,
  });

  final Widget child;

  /// Upper bound for the width the scene is laid out with (wrapping content
  /// such as chips needs a finite width).
  final double maxDesignWidth;

  /// Max share of the screen height the scene may occupy; `null` = no limit.
  final double? maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final fraction = maxHeightFraction;
    final maxHeight = fraction == null ? double.infinity : MediaQuery.sizeOf(context).height * fraction;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDesignWidth),
          child: child,
        ),
      ),
    );
  }
}

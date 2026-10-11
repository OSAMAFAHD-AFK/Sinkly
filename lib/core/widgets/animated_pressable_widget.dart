import 'package:flutter/widgets.dart';

import '../utils/functions/app_functions.dart';

/// Wraps any child with a soft "squish" scale on press + optional haptic.
/// Used by buttons, cards and chips so every tap feels physical.
class AnimatedPressableWidget extends StatefulWidget {
  const AnimatedPressableWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.enableHaptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool enableHaptic;
  final String? semanticLabel;

  @override
  State<AnimatedPressableWidget> createState() => _AnimatedPressableWidgetState();
}

class _AnimatedPressableWidgetState extends State<AnimatedPressableWidget> {
  bool _isPressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_enabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.enableHaptic) AppFunctions.selectionHaptic();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

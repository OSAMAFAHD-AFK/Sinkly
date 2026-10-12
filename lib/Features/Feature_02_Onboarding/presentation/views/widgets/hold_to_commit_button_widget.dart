import 'package:flutter/material.dart';

import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';

/// Press-and-hold pill that fills with sky blue. Releasing early drains it.
/// The deliberate physical effort turns a tap into a real commitment
/// (a proven conversion pattern), with haptic ticks while filling.
class HoldToCommitButtonWidget extends StatefulWidget {
  const HoldToCommitButtonWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.completedLabel,
    required this.onCommitted,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.isCompleted = false,
    this.onProgressChanged,
  });

  final String label;
  final String hint;
  final String completedLabel;
  final VoidCallback onCommitted;
  final Duration holdDuration;
  final bool isCompleted;

  /// 0 … 1 hold progress, reported every frame (drives the commitment scene).
  final ValueChanged<double>? onProgressChanged;

  @override
  State<HoldToCommitButtonWidget> createState() => _HoldToCommitButtonWidgetState();
}

class _HoldToCommitButtonWidgetState extends State<HoldToCommitButtonWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.holdDuration, value: widget.isCompleted ? 1 : 0)
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);

  int _lastHapticQuarter = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.isCompleted;
  }

  void _onTick() {
    widget.onProgressChanged?.call(_controller.value);
    final quarter = (_controller.value * 4).floor();
    if (_controller.status == AnimationStatus.forward && quarter > _lastHapticQuarter) AppFunctions.lightHaptic();
    _lastHapticQuarter = quarter;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      setState(() => _completed = true);
      AppFunctions.successHaptic();
      widget.onCommitted();
    }
  }

  void _startHold() {
    if (_completed) return;
    _controller.forward();
  }

  void _cancelHold() {
    if (_completed) return;
    _controller.animateBack(0, duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: widget.label,
          onTap: _completed ? null : () => _controller.forward(),
          child: Listener(
            onPointerDown: (_) => _startHold(),
            onPointerUp: (_) => _cancelHold(),
            onPointerCancel: (_) => _cancelHold(),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                return Transform.scale(
                  scale: 1 - value * 0.03 + (_completed ? 0.03 : 0),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.pillAll,
                      color: AppColors.glassFillStrong,
                      border: Border.all(color: _completed ? AppColors.primary : Colors.white, width: 1.5),
                      boxShadow: value > 0 || _completed
                          ? AppShadows.primaryGlow(strength: 0.3 + value * 0.7)
                          : AppShadows.floating,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadii.pillAll,
                      child: Stack(
                        children: [
                          // Sky fill growing from the start edge.
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              heightFactor: 1,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(gradient: AppGradients.primaryButton),
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _completed ? Icons.verified_rounded : Icons.fingerprint_rounded,
                                    color: AppColors.onPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      _completed ? widget.completedLabel : widget.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.button,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedOpacity(
          opacity: _completed ? 0 : 1,
          duration: AppDurations.fast,
          child: Text(widget.hint, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}

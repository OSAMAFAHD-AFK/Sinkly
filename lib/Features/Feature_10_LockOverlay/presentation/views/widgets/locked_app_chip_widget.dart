import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/shared_core_models.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';

/// "Instagram · paused" pill. On entry it gives a soft "knock-knock" shake
/// (the app tried to open) and the padlock clicks shut.
class LockedAppChipWidget extends StatelessWidget {
  const LockedAppChipWidget({super.key, required this.app});

  /// Null → a generic "Your apps · paused".
  final BlockableAppModel? app;

  @override
  Widget build(BuildContext context) {
    final name = app?.displayName ?? context.tr('lock_overlay_apps_generic');
    return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: AppColors.glassFillStrong,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (app != null)
                      Opacity(opacity: 0.55, child: BlockableAppIconWidget(app: app!, size: 32))
                    else
                      Container(
                        decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                        child: const Center(child: Icon(Icons.apps_rounded, size: 18, color: AppColors.primaryInk)),
                      ),
                    PositionedDirectional(
                      end: -5,
                      bottom: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const _ClosingPadlock(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  context.tr('lock_overlay_chip_paused', {'app': name}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.6, curve: Curves.easeOutBack, duration: 500.ms)
        .then(delay: 120.ms)
        .shake(hz: 6, offset: const Offset(4, 0), duration: 420.ms);
  }
}

/// Open padlock that snaps shut right after the chip lands.
class _ClosingPadlock extends StatefulWidget {
  const _ClosingPadlock();

  @override
  State<_ClosingPadlock> createState() => _ClosingPadlockState();
}

class _ClosingPadlockState extends State<_ClosingPadlock> {
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _closed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: Icon(
        _closed ? Icons.lock_rounded : Icons.lock_open_rounded,
        key: ValueKey(_closed),
        size: 10,
        color: Colors.white,
      ),
    );
  }
}

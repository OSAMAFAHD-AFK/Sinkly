import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/models/blockable_app_model.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/blockable_app_icon_widget.dart';
import '../../../../../core/widgets/custom_card_container.dart';

/// Screen 3 illustration: a pile of dishes on one side, a glowing phone
/// pulling attention with endless notifications on the other.
class PhoneEscapeIllustrationWidget extends StatelessWidget {
  const PhoneEscapeIllustrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final tiktok = BlockableAppModel.byId('tiktok')!;
    final instagram = BlockableAppModel.byId('instagram')!;

    return SizedBox(
      height: 230,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dirty dish pile (left).
          PositionedDirectional(
            start: 6,
            bottom: 18,
            child: Column(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 44)),
                Transform.translate(
                  offset: const Offset(0, -14),
                  child: const Text('🥣', style: TextStyle(fontSize: 40)),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: const Text('🍳', style: TextStyle(fontSize: 36)),
                ),
              ],
            ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.01, end: 0.01, duration: 1800.ms),
          ),
          // Phone mock.
          PositionedDirectional(
            end: 18,
            top: 4,
            child:
                CustomCardContainer(
                      width: 150,
                      height: 214,
                      borderRadius: BorderRadius.circular(30),
                      fillColor: AppColors.glassFillStrong,
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                      child: Column(
                        children:
                            [
                                  Container(
                                    width: 44,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.ink,
                                      borderRadius: AppRadii.pillAll,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _NotificationPill(app: tiktok, text: context.tr('pain_notification_one')),
                                  const SizedBox(height: 8),
                                  _NotificationPill(app: instagram, text: context.tr('pain_notification_two')),
                                  const SizedBox(height: 8),
                                  _NotificationPill(app: tiktok, text: context.tr('pain_notification_three')),
                                ]
                                .animate(interval: 450.ms, delay: 400.ms)
                                .fadeIn(duration: 300.ms)
                                .slideX(begin: context.flipX(0.3), curve: Curves.easeOutBack),
                      ),
                    )
                    // The phone buzzes for attention, then rests — like real life.
                    .animate(onPlay: (c) => c.repeat(), delay: 1800.ms)
                    .shake(hz: 7, rotation: 0.035, duration: 600.ms)
                    .then(delay: 2200.ms),
          ),
          // Guilt meter badge.
          PositionedDirectional(
            start: 70,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: AppRadii.pillAll,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: AppShadows.soft,
              ),
              child: Text(
                context.tr('pain_guilt_badge'),
                style: AppTextStyles.label.copyWith(color: AppColors.danger, letterSpacing: 0.2),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.96, end: 1.04, duration: 900.ms),
          ),
        ],
      ),
    );
  }
}

class _NotificationPill extends StatelessWidget {
  const _NotificationPill({required this.app, required this.text});

  final BlockableAppModel app;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: AppRadii.smallAll, boxShadow: AppShadows.soft),
      child: Row(
        children: [
          BlockableAppIconWidget(app: app, size: 24),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.2, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/functions/app_functions.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/animated_pressable_widget.dart';
import '../../../../../core/widgets/custom_primary_button.dart';
import '../../../../../core/widgets/glass_bottom_sheet.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/heroine_speech_bubble_widget.dart';
import '../../../../Feature_02_Onboarding/presentation/views/widgets/rising_emoji_particles_widget.dart';
import '../../../data/models/share_invite_outcome.dart';

/// Sends the message through the system share sheet.
typedef ShareInviteCallback = Future<ShareInviteOutcome> Function(String message, String subject, Rect? origin);

/// "Share with a friend": ONE short, friendly note (the problem → how Sinkly
/// solves it → the link), shown exactly as the friend will receive it. The
/// heroine reacts; no rewards, no choices to make. If the system share sheet
/// can't open, the message is copied instead so the user is never stuck.
Future<void> showShareInviteSheet(BuildContext context, {required ShareInviteCallback onShare}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _ShareInviteSheetContent(onShare: onShare),
  );
}

/// What the heroine is reacting to.
enum _Mood { hello, copied, shared }

class _ShareInviteSheetContent extends StatefulWidget {
  const _ShareInviteSheetContent({required this.onShare});

  final ShareInviteCallback onShare;

  @override
  State<_ShareInviteSheetContent> createState() => _ShareInviteSheetContentState();
}

class _ShareInviteSheetContentState extends State<_ShareInviteSheetContent> {
  static const Duration _tapCooldown = Duration(milliseconds: 800);

  final GlobalKey _shareButtonKey = GlobalKey();
  _Mood _mood = _Mood.hello;
  bool _copyFailedShare = false;
  DateTime? _lastShareTap;

  String _message(BuildContext context) => context.tr('share_message', {'link': AppConstants.inviteLink});

  Future<void> _copy({bool afterFailedShare = false}) async {
    await Clipboard.setData(ClipboardData(text: _message(context)));
    AppFunctions.lightHaptic();
    if (mounted) {
      setState(() {
        _mood = _Mood.copied;
        _copyFailedShare = afterFailedShare;
      });
    }
  }

  Future<void> _share() async {
    // Only a short cooldown against double taps. The button is NEVER locked
    // while the system sheet is open, so it can't get stuck if the platform
    // is slow to answer.
    final now = DateTime.now();
    final last = _lastShareTap;
    if (last != null && now.difference(last) < _tapCooldown) return;
    _lastShareTap = now;

    // iPad anchors its share popover to the button.
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final message = _message(context);
    final subject = context.tr('share_subject');

    final outcome = await widget.onShare(message, subject, origin);
    if (!mounted) return;
    switch (outcome) {
      case ShareInviteOutcome.shared:
        // A little celebration, then the sheet bows out on its own.
        AppFunctions.successHaptic();
        setState(() => _mood = _Mood.shared);
        await Future<void>.delayed(const Duration(milliseconds: 1700));
        if (mounted) Navigator.of(context).maybePop();
      case ShareInviteOutcome.dismissed:
        break;
      case ShareInviteOutcome.failed:
        await _copy(afterFailedShare: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeroineGreeting(mood: _mood, copyFailedShare: _copyFailedShare),
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr('share_sheet_title'), textAlign: TextAlign.center, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            context.tr('share_sheet_subtitle'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          _MessagePreview(message: _message(context)),
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: _shareButtonKey,
            child: CustomPrimaryButton(
              label: context.tr('share_cta'),
              icon: Icons.ios_share_rounded,
              showShimmer: true,
              onPressed: _share,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _CopyButton(copied: _mood == _Mood.copied, onTap: _copy),
        ].animate(interval: 45.ms).fadeIn(duration: 320.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
      ),
    );
  }
}

/// She waves hello, claps when the message is copied and jumps for joy once
/// it has been shared.
class _HeroineGreeting extends StatelessWidget {
  const _HeroineGreeting({required this.mood, required this.copyFailedShare});

  final _Mood mood;
  final bool copyFailedShare;

  static const double _width = 92;

  @override
  Widget build(BuildContext context) {
    final (pose, motion, bubbleKey) = switch (mood) {
      _Mood.hello => (HeroinePose.waveJoy, HeroineMotion.wave, 'share_bubble_hello'),
      _Mood.copied => (
        HeroinePose.clapHappy,
        HeroineMotion.clap,
        copyFailedShare ? 'share_bubble_copied_instead' : 'share_bubble_copied',
      ),
      _Mood.shared => (HeroinePose.joyJump, HeroineMotion.jumpJoy, 'share_bubble_shared'),
    };
    final height = HeroineCharacterWidget.heightFor(_width);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: _width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -10,
                  right: -10,
                  bottom: 6,
                  height: _width + 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.4), AppColors.primary.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                HeroineCharacterWidget(width: _width, pose: pose, motion: motion),
                if (mood == _Mood.shared)
                  const Positioned(
                    left: _width / 2 - 30,
                    top: 18,
                    child: RisingEmojiParticlesWidget(
                      emojis: ['💙', '💌', '✨', '💛', '💙'],
                      rise: 70,
                      spread: 32,
                      fontSize: 15,
                      interval: Duration(milliseconds: 240),
                      lifetime: Duration(milliseconds: 1400),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: height * 0.45),
              child: HeroineSpeechBubbleSwitcherWidget(text: context.tr(bubbleKey), maxWidth: 200),
            ),
          ),
        ],
      ),
    );
  }
}

/// The message exactly as the friend will see it: a "sent" chat bubble on a
/// soft conversation background.
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.7),
        borderRadius: AppRadii.cardAll,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.visibility_rounded, size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('share_preview_label'),
                    style: AppTextStyles.label.copyWith(letterSpacing: 0, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(20),
                  topEnd: Radius.circular(20),
                  bottomStart: Radius.circular(20),
                  bottomEnd: Radius.circular(5),
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LinkHighlightedText(message: message),
                  const SizedBox(height: 4),
                  const Icon(Icons.done_all_rounded, size: 15, color: AppColors.primaryDeep),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message text with the invite link styled like a real link.
class _LinkHighlightedText extends StatelessWidget {
  const _LinkHighlightedText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const link = AppConstants.inviteLink;
    final base = AppTextStyles.bodyStrong.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500);
    final index = message.indexOf(link);
    if (index < 0) return Text(message, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: message.substring(0, index)),
          const TextSpan(
            text: link,
            style: TextStyle(color: AppColors.primaryInk, decoration: TextDecoration.underline),
          ),
          TextSpan(text: message.substring(index + link.length)),
        ],
      ),
    );
  }
}

/// Secondary "Copy message" that morphs into a green "Copied!" check.
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.copied, required this.onTap});

  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = copied ? AppColors.success : AppColors.primaryInk;
    return AnimatedPressableWidget(
      onTap: onTap,
      semanticLabel: context.tr('share_copy'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Row(
            key: ValueKey(copied),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(copied ? Icons.check_circle_rounded : Icons.copy_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.tr(copied ? 'share_copied' : 'share_copy'),
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

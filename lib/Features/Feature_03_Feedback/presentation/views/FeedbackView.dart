import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/app_toast_widget.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../manager/feedback_cubit.dart';
import 'widgets/feedback_category_grid_widget.dart';
import 'widgets/feedback_composer_widget.dart';
import 'widgets/feedback_hero_card_widget.dart';
import 'widgets/feedback_success_dialog_widget.dart';

/// "Help Build Sinkly" — the customer-driven roadmap screen.
class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onStateChanged(BuildContext context, FeedbackState state) async {
    if (state.status == FeedbackSubmissionStatus.success) {
      AppFunctions.successHaptic();
      FocusScope.of(context).unfocus();
      await showFeedbackSuccessDialog(context);
      if (!context.mounted) return;
      _messageController.clear();
      context.read<FeedbackCubit>().resetForm();
    } else if (state.status == FeedbackSubmissionStatus.failure && state.failureKey != null) {
      AppFunctions.showSnack(context, context.tr(state.failureKey!), tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      child: GlassScreenScaffold(
        palette: MeshPalette.calm,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  children: [
                    GlassIconButton.back(context: context),
                    Expanded(
                      child: Text(
                        context.tr('feedback_screen_title'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.sm,
                    AppSpacing.screenGutter,
                    AppSpacing.lg,
                  ),
                  children: [
                    const FeedbackHeroCardWidget()
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .scaleXY(begin: 0.96, end: 1, duration: 600.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeaderWidget(title: context.tr('feedback_category_label')),
                    const FeedbackCategoryGridWidget().animate(delay: 140.ms).fadeIn().slideY(begin: 0.06),
                    const SizedBox(height: AppSpacing.md),
                    FeedbackComposerWidget(
                      controller: _messageController,
                    ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.06),
                  ],
                ),
              ),
              // ── Submit ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.xs,
                  AppSpacing.screenGutter,
                  AppSpacing.md,
                ),
                child: BlocBuilder<FeedbackCubit, FeedbackState>(
                  buildWhen: (previous, current) =>
                      previous.canSubmit != current.canSubmit || previous.status != current.status,
                  builder: (context, state) => CustomPrimaryButton(
                    label: context.tr('feedback_submit_cta'),
                    // Trailing + matchTextDirection: right→ in EN, left← in AR.
                    trailingIcon: Icons.send_rounded,
                    isLoading: state.status == FeedbackSubmissionStatus.submitting,
                    onPressed: state.canSubmit ? context.read<FeedbackCubit>().submitFeedback : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

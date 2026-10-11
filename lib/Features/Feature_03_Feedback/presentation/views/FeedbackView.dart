import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/functions/app_functions.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/widgets/custom_card_container.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_screen_scaffold.dart';
import '../../../../core/widgets/mesh_gradient_background_widget.dart';
import '../../../../core/widgets/section_header_widget.dart';
import '../../data/models/user_feedback_model.dart';
import '../manager/feedback_cubit.dart';
import 'widgets/feedback_category_chip_widget.dart';
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
      AppFunctions.showSnack(context, context.tr(state.failureKey!));
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
                    const _FeedbackHeroHeaderCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeaderWidget(title: context.tr('feedback_category_label')),
                    const _FeedbackCategoryChipsRow()
                        .animate(delay: 100.ms)
                        .fadeIn()
                        .slideX(begin: context.flipX(0.05)),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeaderWidget(title: context.tr('feedback_message_label')),
                    CustomTextField(
                      controller: _messageController,
                      maxLines: 5,
                      maxLength: 600,
                      hintText: context.tr('feedback_input_placeholder'),
                      onChanged: context.read<FeedbackCubit>().updateMessage,
                    ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.06),
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
                    icon: Icons.send_rounded,
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

class _FeedbackHeroHeaderCard extends StatelessWidget {
  const _FeedbackHeroHeaderCard();

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: AppRadii.mediumAll,
                  boxShadow: AppShadows.primaryGlow(strength: 0.6),
                ),
                child: const Text('🚀', style: TextStyle(fontSize: 28)),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -4, duration: 1400.ms, curve: Curves.easeInOut),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('feedback_hero_title'), style: AppTextStyles.title.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(context.tr('feedback_hero_description'), style: AppTextStyles.body.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCategoryChipsRow extends StatelessWidget {
  const _FeedbackCategoryChipsRow();

  @override
  Widget build(BuildContext context) {
    final selected = context.select((FeedbackCubit c) => c.state.category);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final category in FeedbackCategory.values) ...[
            FeedbackCategoryChipWidget(
              emoji: category.emoji,
              label: context.tr(category.translationKey),
              isSelected: category == selected,
              onTap: () => context.read<FeedbackCubit>().selectCategory(category),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/shared_core_models.dart';
import '../utils/app_localizations.dart';
import '../utils/functions/app_functions.dart';
import '../utils/style.dart';
import 'app_category_icon_widget.dart';
import 'blockable_app_icon_widget.dart';
import 'custom_card_container.dart';

/// Screen-Time-style picker for the apps installed on the device:
///
/// * "All apps & categories" row on top;
/// * one row per category — the circle selects the whole category (also
///   covering apps installed later), the row expands to pick single apps;
/// * "All" / "3 of 7" hints, live search, smooth expand/collapse.
///
/// Pure UI: the caller owns [selection] and persists [onChanged].
class AppCategoryPickerWidget extends StatefulWidget {
  const AppCategoryPickerWidget({
    super.key,
    required this.apps,
    required this.selection,
    required this.onChanged,
    this.isLoading = false,
  });

  final List<BlockableAppModel> apps;
  final AppSelectionModel selection;
  final ValueChanged<AppSelectionModel> onChanged;
  final bool isLoading;

  @override
  State<AppCategoryPickerWidget> createState() => _AppCategoryPickerWidgetState();
}

class _AppCategoryPickerWidgetState extends State<AppCategoryPickerWidget> {
  final TextEditingController _search = TextEditingController();
  final Set<AppCategory> _expanded = {};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _emit(AppSelectionModel selection) {
    AppFunctions.selectionHaptic();
    widget.onChanged(selection);
  }

  Map<AppCategory, List<BlockableAppModel>> get _grouped {
    final map = <AppCategory, List<BlockableAppModel>>{};
    for (final app in widget.apps) {
      (map[app.category] ??= []).add(app);
    }
    // Keep Screen Time's category order; hide empty categories.
    return {
      for (final category in AppCategory.values)
        if (map[category] != null) category: map[category]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(controller: _search, onChanged: (value) => setState(() => _query = value.trim().toLowerCase())),
        const SizedBox(height: AppSpacing.sm),
        CustomCardContainer(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppRadii.cardAll,
            child: AnimatedSize(
              duration: AppDurations.medium,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: widget.isLoading
                  ? const _LoadingRows()
                  : _query.isEmpty
                  ? _buildCategories(context)
                  : _buildSearchResults(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context) {
    final grouped = _grouped;
    final selection = widget.selection;
    final allSelected = selection.isAllSelected(widget.apps);

    return Column(
      children: [
        _PickerRow(
          leading: _CheckCircle(state: allSelected ? _CheckState.on : _CheckState.off),
          icon: const AppCategoryIconWidget(),
          title: context.tr('apps_picker_all'),
          isHeader: true,
          onTap: () => _emit(selection.toggleAll(widget.apps)),
          onLeadingTap: () => _emit(selection.toggleAll(widget.apps)),
        ),
        for (final (index, entry) in grouped.entries.indexed) ...[
          const _RowDivider(),
          _buildCategory(
            context,
            entry.key,
            entry.value,
          ).animate(delay: (40 * index).ms).fadeIn(duration: 260.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),
        ],
      ],
    );
  }

  Widget _buildCategory(BuildContext context, AppCategory category, List<BlockableAppModel> apps) {
    final selection = widget.selection;
    final whole = selection.isCategorySelected(category);
    final picked = selection.selectedInCategory(category, apps);
    final expanded = _expanded.contains(category);
    final checkState = whole || picked == apps.length
        ? _CheckState.on
        : picked > 0
        ? _CheckState.partial
        : _CheckState.off;

    return Column(
      children: [
        _PickerRow(
          leading: _CheckCircle(state: checkState),
          icon: AppCategoryIconWidget(category: category),
          title: context.tr(category.translationKey),
          trailingHint: whole
              ? context.tr('apps_picker_all_label')
              : picked > 0
              ? context.tr('apps_picker_partial', {'picked': '$picked', 'total': '${apps.length}'})
              : null,
          expanded: expanded,
          onLeadingTap: () => _emit(selection.toggleCategory(category)),
          onTap: () => setState(() => expanded ? _expanded.remove(category) : _expanded.add(category)),
        ),
        AnimatedSize(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? ColoredBox(
                  color: AppColors.primarySoft.withValues(alpha: 0.45),
                  child: Column(children: [for (final app in apps) _buildAppRow(context, app, indent: true)]),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildAppRow(BuildContext context, BlockableAppModel app, {bool indent = false}) {
    final selected = widget.selection.isAppSelected(app);
    void toggle() => _emit(widget.selection.toggleApp(app, widget.apps));
    return _PickerRow(
      leading: _CheckCircle(state: selected ? _CheckState.on : _CheckState.off),
      icon: BlockableAppIconWidget(app: app, size: 32),
      title: app.displayName,
      indent: indent,
      onTap: toggle,
      onLeadingTap: toggle,
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final matches = widget.apps.where((app) => app.displayName.toLowerCase().contains(_query)).toList();
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          context.tr('apps_picker_no_results', {'query': _search.text.trim()}),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      );
    }
    return Column(
      children: [
        for (final (index, app) in matches.indexed) ...[if (index > 0) const _RowDivider(), _buildAppRow(context, app)],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintText: context.tr('apps_picker_search'),
          hintStyle: AppTextStyles.caption,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inkMuted, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: context.tr('close'),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkMuted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.leading,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.onLeadingTap,
    this.trailingHint,
    this.expanded,
    this.indent = false,
    this.isHeader = false,
  });

  final Widget leading;
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onLeadingTap;
  final String? trailingHint;

  /// null = not expandable (app rows / header).
  final bool? expanded;
  final bool indent;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final expandable = expanded != null;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: indent ? 54 : 68),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(indent ? AppSpacing.lg : AppSpacing.xs, 6, AppSpacing.sm, 6),
            child: Row(
              children: [
                // Bigger tap target than the circle itself.
                Semantics(
                  button: true,
                  label: title,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onLeadingTap,
                    child: Padding(padding: const EdgeInsets.all(AppSpacing.xs), child: leading),
                  ),
                ),
                const SizedBox(width: 4),
                icon,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (isHeader ? AppTextStyles.titleSmall : AppTextStyles.bodyStrong).copyWith(fontSize: 15),
                  ),
                ),
                if (trailingHint != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(trailingHint!, style: AppTextStyles.caption.copyWith(color: AppColors.primaryInk)),
                ],
                if (expandable) ...[
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded! ? (context.isRtl ? -0.25 : 0.25) : 0,
                    duration: AppDurations.medium,
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CheckState { off, partial, on }

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.state});

  final _CheckState state;

  @override
  Widget build(BuildContext context) {
    final on = state == _CheckState.on;
    // No overshooting curve here: it would lerp the shadow/border past zero.
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: on ? AppGradients.primaryButton : null,
        color: on ? null : Colors.white,
        border: Border.all(color: on ? AppColors.primary : AppColors.inkMuted.withValues(alpha: 0.45), width: 1.6),
        boxShadow: on ? AppShadows.primaryGlow(strength: 0.35) : const [],
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: switch (state) {
          _CheckState.on => const Icon(Icons.check_rounded, key: ValueKey('on'), size: 16, color: AppColors.onPrimary),
          _CheckState.partial => Container(
            key: const ValueKey('partial'),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          _CheckState.off => const SizedBox.shrink(key: ValueKey('off')),
        },
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, indent: AppSpacing.md, endIndent: AppSpacing.md);
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.6),
              borderRadius: AppRadii.mediumAll,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white),
      ],
    );
  }
}

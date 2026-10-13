import 'package:equatable/equatable.dart';

import 'app_category_model.dart';
import 'blockable_app_model.dart';

/// Which apps the user wants locked, picked the Screen-Time way: whole
/// categories (which also cover apps installed later) and/or single apps.
///
/// On iOS the real selection lives natively as Apple's opaque tokens; only
/// its size is mirrored here in [systemPickerCount].
class AppSelectionModel extends Equatable {
  const AppSelectionModel({this.appIds = const [], this.categoryIds = const [], this.systemPickerCount = 0});

  final List<String> appIds;
  final List<String> categoryIds;

  /// Apps + categories chosen in Apple's FamilyActivityPicker (iOS only).
  final int systemPickerCount;

  bool get isEmpty => appIds.isEmpty && categoryIds.isEmpty && systemPickerCount == 0;

  bool isCategorySelected(AppCategory category) => categoryIds.contains(category.id);

  bool isAppSelected(BlockableAppModel app) => appIds.contains(app.id) || categoryIds.contains(app.category.id);

  /// Every category present in [apps] is selected.
  bool isAllSelected(List<BlockableAppModel> apps) {
    final present = apps.map((app) => app.category.id).toSet();
    return present.isNotEmpty && present.every(categoryIds.contains);
  }

  /// Apps that end up locked (explicit + covered by a selected category).
  List<BlockableAppModel> selectedApps(List<BlockableAppModel> apps) => apps.where(isAppSelected).toList();

  /// Number shown on the CTA ("Confirm apps (7)").
  int selectedCount(List<BlockableAppModel> apps) => selectedApps(apps).length + systemPickerCount;

  /// Selected apps of one category (for the "3/7" hint on a category row).
  int selectedInCategory(AppCategory category, List<BlockableAppModel> apps) =>
      apps.where((app) => app.category == category && isAppSelected(app)).length;

  AppSelectionModel toggleCategory(AppCategory category) {
    if (isCategorySelected(category)) {
      return copyWith(categoryIds: categoryIds.where((id) => id != category.id).toList());
    }
    // The whole category now covers its apps → drop redundant explicit picks.
    return AppSelectionModel(
      appIds: appIds.where((id) => BlockableAppModel.byId(id)?.category != category).toList(),
      categoryIds: [...categoryIds, category.id],
      systemPickerCount: systemPickerCount,
    );
  }

  /// Toggling one app inside a fully-selected category "breaks" the category
  /// into its remaining apps (exactly like the Screen Time picker).
  AppSelectionModel toggleApp(BlockableAppModel app, List<BlockableAppModel> apps) {
    if (categoryIds.contains(app.category.id)) {
      final siblings = apps.where((other) => other.category == app.category && other.id != app.id).map((a) => a.id);
      return AppSelectionModel(
        appIds: {...appIds, ...siblings}.toList(),
        categoryIds: categoryIds.where((id) => id != app.category.id).toList(),
        systemPickerCount: systemPickerCount,
      );
    }
    return copyWith(
      appIds: appIds.contains(app.id) ? appIds.where((id) => id != app.id).toList() : [...appIds, app.id],
    );
  }

  /// "All apps & categories" row.
  AppSelectionModel toggleAll(List<BlockableAppModel> apps) {
    if (isAllSelected(apps)) return AppSelectionModel(systemPickerCount: systemPickerCount);
    final present = {for (final app in apps) app.category.id};
    return AppSelectionModel(
      categoryIds: AppCategory.values.map((c) => c.id).where(present.contains).toList(),
      systemPickerCount: systemPickerCount,
    );
  }

  /// Drops explicit picks of apps that aren't installed on this device.
  AppSelectionModel keepInstalled(List<BlockableAppModel> apps) {
    final installed = {for (final app in apps) app.id};
    return copyWith(appIds: appIds.where(installed.contains).toList());
  }

  AppSelectionModel copyWith({List<String>? appIds, List<String>? categoryIds, int? systemPickerCount}) =>
      AppSelectionModel(
        appIds: List.unmodifiable(appIds ?? this.appIds),
        categoryIds: List.unmodifiable(categoryIds ?? this.categoryIds),
        systemPickerCount: systemPickerCount ?? this.systemPickerCount,
      );

  @override
  List<Object?> get props => [appIds, categoryIds, systemPickerCount];
}

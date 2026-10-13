import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_category_model.dart';

/// An app the user can choose to lock after meals.
///
/// * Android: built from the real installed apps (`PackageManager`), with the
///   app's own icon ([iconBytes]) and category; [platformIdentifier] is the
///   package name that the native blocker watches.
/// * iOS: apps are picked in Apple's FamilyActivityPicker (opaque tokens kept
///   natively), so only the curated [catalog] is used for illustrations.
@immutable
class BlockableAppModel {
  const BlockableAppModel({
    required this.id,
    required this.displayName,
    required this.brandColorValue,
    required this.platformIdentifier,
    this.category = AppCategory.other,
    this.iconBytes,
  });

  final String id;
  final String displayName;
  final int brandColorValue;
  final String platformIdentifier;
  final AppCategory category;

  /// PNG of the real launcher icon (installed apps on Android).
  final Uint8List? iconBytes;

  Color get brandColor => Color(brandColorValue);

  BlockableAppModel withInstalledData({required AppCategory category, Uint8List? iconBytes}) => BlockableAppModel(
    id: id,
    displayName: displayName,
    brandColorValue: brandColorValue,
    platformIdentifier: platformIdentifier,
    category: category,
    iconBytes: iconBytes ?? this.iconBytes,
  );

  /// Popular distracting apps: brand art for illustrations, onboarding
  /// defaults and the fallback list when the device list is unavailable.
  static const List<BlockableAppModel> catalog = [
    BlockableAppModel(
      id: 'tiktok',
      displayName: 'TikTok',
      brandColorValue: 0xFF111111,
      platformIdentifier: 'com.zhiliaoapp.musically',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'instagram',
      displayName: 'Instagram',
      brandColorValue: 0xFFE1306C,
      platformIdentifier: 'com.instagram.android',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'x',
      displayName: 'X',
      brandColorValue: 0xFF14171A,
      platformIdentifier: 'com.twitter.android',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'youtube',
      displayName: 'YouTube',
      brandColorValue: 0xFFFF0000,
      platformIdentifier: 'com.google.android.youtube',
      category: AppCategory.entertainment,
    ),
    BlockableAppModel(
      id: 'snapchat',
      displayName: 'Snapchat',
      brandColorValue: 0xFFF7D600,
      platformIdentifier: 'com.snapchat.android',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'facebook',
      displayName: 'Facebook',
      brandColorValue: 0xFF1877F2,
      platformIdentifier: 'com.facebook.katana',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'reddit',
      displayName: 'Reddit',
      brandColorValue: 0xFFFF4500,
      platformIdentifier: 'com.reddit.frontpage',
      category: AppCategory.social,
    ),
    BlockableAppModel(
      id: 'twitch',
      displayName: 'Twitch',
      brandColorValue: 0xFF9146FF,
      platformIdentifier: 'tv.twitch.android.app',
      category: AppCategory.entertainment,
    ),
  ];

  /// Apps pre-selected on the onboarding app picker (kept only if installed).
  static const List<String> defaultSelectedIds = ['tiktok', 'instagram'];

  // ── Registry of the apps installed on this device ─────────────────────
  static final Map<String, BlockableAppModel> _installed = {};

  /// Installed apps (empty until the device list is loaded / on iOS).
  static List<BlockableAppModel> get installed => List.unmodifiable(_installed.values);

  /// Called by the installed-apps data source once the device list is read.
  static void registerInstalled(Iterable<BlockableAppModel> apps) {
    _installed
      ..clear()
      ..addEntries(apps.map((app) => MapEntry(app.id, app)));
  }

  /// Catalog entry for a package (so TikTok keeps id `tiktok` + brand art).
  static BlockableAppModel? catalogForPackage(String packageName) {
    for (final app in catalog) {
      if (app.platformIdentifier == packageName) return app;
    }
    return null;
  }

  static BlockableAppModel? byId(String id) {
    final installedApp = _installed[id];
    if (installedApp != null) return installedApp;
    for (final app in catalog) {
      if (app.id == id) return app;
    }
    return null;
  }

  static List<BlockableAppModel> fromIds(Iterable<String> ids) =>
      ids.map(byId).whereType<BlockableAppModel>().toList(growable: false);

  /// Apps covered by a selection: explicit ids + every installed app of the
  /// selected categories.
  static List<BlockableAppModel> resolveSelection({
    required Iterable<String> appIds,
    required Iterable<String> categoryIds,
  }) {
    final categories = categoryIds.toSet();
    final result = <String, BlockableAppModel>{
      for (final app in fromIds(appIds)) app.id: app,
      for (final app in _installed.values)
        if (categories.contains(app.category.id)) app.id: app,
    };
    return result.values.toList(growable: false);
  }
}

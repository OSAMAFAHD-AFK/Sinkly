import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/shared_core_models.dart';

/// How the "apps to lock" picker works on this platform.
enum AppPickerMode {
  /// Android (and dev fallback): we read the installed apps and render our
  /// own category list.
  inAppList,

  /// iOS: apps can't be listed by any app — Apple's FamilyActivityPicker is
  /// embedded instead and returns opaque tokens (kept natively).
  systemPicker,
}

/// Reads the apps installed on the device, grouped into [AppCategory].
///
/// * Android → MethodChannel `sinkly/installed_apps` (MainActivity.kt):
///   launcher apps via `PackageManager.queryIntentActivities(MAIN/LAUNCHER)`
///   (visible on Android 11+ thanks to the `<queries>` manifest entry — no
///   QUERY_ALL_PACKAGES needed), with label, `ApplicationInfo.category` and
///   the launcher icon as PNG.
/// * iOS → not possible by design (privacy); see [AppPickerMode.systemPicker].
abstract class InstalledAppsPlatformDataSource {
  AppPickerMode get pickerMode;

  /// Installed apps sorted by name. Also registers them in
  /// [BlockableAppModel] so ids resolve everywhere in the app.
  Future<List<BlockableAppModel>> loadInstalledApps();
}

class MethodChannelInstalledAppsDataSource implements InstalledAppsPlatformDataSource {
  static const MethodChannel _channel = MethodChannel('sinkly/installed_apps');

  List<BlockableAppModel>? _cache;

  @override
  AppPickerMode get pickerMode => !kIsWeb && Platform.isIOS ? AppPickerMode.systemPicker : AppPickerMode.inAppList;

  @override
  Future<List<BlockableAppModel>> loadInstalledApps() async {
    if (_cache != null) return _cache!;
    if (pickerMode == AppPickerMode.systemPicker) return _cache = const [];

    List<BlockableAppModel> apps;
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('getInstalledApps', {'iconSize': 96});
      apps = (raw ?? const []).map(_fromPlatform).toList();
      if (apps.isEmpty) apps = sampleApps;
    } on MissingPluginException {
      apps = sampleApps; // tests / desktop / web preview
    } on PlatformException catch (error) {
      debugPrint('[InstalledApps] $error');
      apps = sampleApps;
    }
    apps.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    BlockableAppModel.registerInstalled(apps);
    return _cache = apps;
  }

  static BlockableAppModel _fromPlatform(Map<Object?, Object?> map) {
    final packageName = map['packageName']! as String;
    final category = AppCategory.fromAndroid((map['category'] as int?) ?? -1, packageName);
    final icon = map['icon'] as Uint8List?;
    // Known distracting apps keep their catalog id (defaults, brand colors).
    final known = BlockableAppModel.catalogForPackage(packageName);
    if (known != null) return known.withInstalledData(category: category, iconBytes: icon);
    return BlockableAppModel(
      id: packageName,
      displayName: (map['name'] as String?)?.trim().isNotEmpty == true ? map['name']! as String : packageName,
      brandColorValue: _colorFor(packageName),
      platformIdentifier: packageName,
      category: category,
      iconBytes: icon,
    );
  }

  /// Stable pastel per package for apps without an icon.
  static int _colorFor(String seed) {
    const palette = [0xFF5AAFE6, 0xFF8C7BFF, 0xFF34C38F, 0xFFFF8A65, 0xFFFFB74D, 0xFFE57399, 0xFF4DB6AC];
    return palette[seed.hashCode.abs() % palette.length];
  }

  /// Realistic sample device used when the native list isn't available
  /// (widget tests, desktop/web previews).
  static final List<BlockableAppModel> sampleApps = [
    ...BlockableAppModel.catalog,
    for (final (id, name, color, category) in const [
      ('com.whatsapp', 'WhatsApp', 0xFF25D366, AppCategory.social),
      ('org.telegram.messenger', 'Telegram', 0xFF2AABEE, AppCategory.social),
      ('com.netflix.mediaclient', 'Netflix', 0xFFE50914, AppCategory.entertainment),
      ('com.spotify.music', 'Spotify', 0xFF1DB954, AppCategory.entertainment),
      ('com.anghami', 'Anghami', 0xFF7B2FF7, AppCategory.entertainment),
      ('com.roblox.client', 'Roblox', 0xFF393B3D, AppCategory.games),
      ('com.king.candycrushsaga', 'Candy Crush', 0xFFFF6FB5, AppCategory.games),
      ('com.tencent.ig', 'PUBG Mobile', 0xFFF2A900, AppCategory.games),
      ('com.amazon.mShop.android.shopping', 'Amazon', 0xFFFF9900, AppCategory.shoppingFood),
      ('com.talabat', 'Talabat', 0xFFFF5A00, AppCategory.shoppingFood),
      ('com.duolingo', 'Duolingo', 0xFF58CC02, AppCategory.education),
      ('com.canva.editor', 'Canva', 0xFF00C4CC, AppCategory.creativity),
      ('com.google.android.calculator', 'Calculator', 0xFF607D8B, AppCategory.utilities),
      ('com.google.android.gm', 'Gmail', 0xFFEA4335, AppCategory.productivity),
      ('com.booking', 'Booking.com', 0xFF003580, AppCategory.travel),
      ('com.strava', 'Strava', 0xFFFC4C02, AppCategory.health),
      ('com.amazon.kindle', 'Kindle', 0xFF146EB4, AppCategory.reading),
    ])
      BlockableAppModel(id: id, displayName: name, brandColorValue: color, platformIdentifier: id, category: category),
  ];
}

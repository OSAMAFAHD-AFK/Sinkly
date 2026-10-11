import 'package:flutter/widgets.dart';

/// A distracting app the user can choose to lock after meals.
///
/// NOTE: On iOS the real implementation uses Apple's FamilyActivityPicker
/// (opaque tokens), and on Android package names. [platformIdentifier] is the
/// hook for that mapping once the native blocking layer is plugged in.
@immutable
class BlockableAppModel {
  const BlockableAppModel({
    required this.id,
    required this.displayName,
    required this.brandColorValue,
    required this.platformIdentifier,
  });

  final String id;
  final String displayName;
  final int brandColorValue;
  final String platformIdentifier;

  Color get brandColor => Color(brandColorValue);

  static const List<BlockableAppModel> catalog = [
    BlockableAppModel(
      id: 'tiktok',
      displayName: 'TikTok',
      brandColorValue: 0xFF111111,
      platformIdentifier: 'com.zhiliaoapp.musically',
    ),
    BlockableAppModel(
      id: 'instagram',
      displayName: 'Instagram',
      brandColorValue: 0xFFE1306C,
      platformIdentifier: 'com.instagram.android',
    ),
    BlockableAppModel(
      id: 'x',
      displayName: 'X',
      brandColorValue: 0xFF14171A,
      platformIdentifier: 'com.twitter.android',
    ),
    BlockableAppModel(
      id: 'youtube',
      displayName: 'YouTube',
      brandColorValue: 0xFFFF0000,
      platformIdentifier: 'com.google.android.youtube',
    ),
    BlockableAppModel(
      id: 'snapchat',
      displayName: 'Snapchat',
      brandColorValue: 0xFFF7D600,
      platformIdentifier: 'com.snapchat.android',
    ),
    BlockableAppModel(
      id: 'facebook',
      displayName: 'Facebook',
      brandColorValue: 0xFF1877F2,
      platformIdentifier: 'com.facebook.katana',
    ),
    BlockableAppModel(
      id: 'reddit',
      displayName: 'Reddit',
      brandColorValue: 0xFFFF4500,
      platformIdentifier: 'com.reddit.frontpage',
    ),
    BlockableAppModel(
      id: 'twitch',
      displayName: 'Twitch',
      brandColorValue: 0xFF9146FF,
      platformIdentifier: 'tv.twitch.android.app',
    ),
  ];

  /// Apps pre-selected on the onboarding app picker.
  static const List<String> defaultSelectedIds = ['tiktok', 'instagram'];

  static BlockableAppModel? byId(String id) {
    for (final app in catalog) {
      if (app.id == id) return app;
    }
    return null;
  }

  static List<BlockableAppModel> fromIds(Iterable<String> ids) =>
      ids.map(byId).whereType<BlockableAppModel>().toList(growable: false);
}

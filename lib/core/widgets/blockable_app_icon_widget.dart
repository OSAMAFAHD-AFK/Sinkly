import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/blockable_app_model.dart';

/// Rounded "app icon" tile: the real launcher icon when known (installed
/// apps on Android), otherwise brand color + glyph, or the app's initial.
/// Optionally shows a small lock badge when the app is currently blocked.
class BlockableAppIconWidget extends StatelessWidget {
  const BlockableAppIconWidget({super.key, required this.app, this.size = 48, this.showLockBadge = false});

  final BlockableAppModel app;
  final double size;
  final bool showLockBadge;

  static IconData? brandIconFor(String appId) => switch (appId) {
    'tiktok' => FontAwesomeIcons.tiktok.data,
    'instagram' => FontAwesomeIcons.instagram.data,
    'x' => FontAwesomeIcons.xTwitter.data,
    'youtube' => FontAwesomeIcons.youtube.data,
    'snapchat' => FontAwesomeIcons.snapchat.data,
    'facebook' => FontAwesomeIcons.facebook.data,
    'reddit' => FontAwesomeIcons.reddit.data,
    'twitch' => FontAwesomeIcons.twitch.data,
    _ => null,
  };

  static IconData iconFor(String appId) => brandIconFor(appId) ?? Icons.apps_rounded;

  @override
  Widget build(BuildContext context) {
    final isInstagram = app.id == 'instagram';
    final isSnapchat = app.id == 'snapchat';
    final realIcon = app.iconBytes;
    final brandIcon = brandIconFor(app.id);
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (realIcon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.24),
              child: Image.memory(
                realIcon,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: pixels,
                filterQuality: FilterQuality.medium,
              ),
            )
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.3),
                color: isInstagram ? null : app.brandColor,
                gradient: isInstagram
                    ? const LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF962FBF)],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: app.brandColor.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: brandIcon != null
                  ? Icon(brandIcon, color: isSnapchat ? Colors.black : Colors.white, size: size * 0.46)
                  : Text(
                      app.displayName.isEmpty ? '?' : app.displayName.characters.first.toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: size * 0.44, fontWeight: FontWeight.w800),
                    ),
            ),
          if (showLockBadge)
            PositionedDirectional(
              end: -4,
              bottom: -4,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Icon(Icons.lock_rounded, size: size * 0.24, color: const Color(0xFF0F1B2D)),
              ),
            ),
        ],
      ),
    );
  }
}

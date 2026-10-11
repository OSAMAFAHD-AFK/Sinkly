import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/blockable_app_model.dart';

/// Rounded "app icon" tile for a distracting app (brand color + glyph).
/// Optionally shows a small lock badge when the app is currently blocked.
class BlockableAppIconWidget extends StatelessWidget {
  const BlockableAppIconWidget({super.key, required this.app, this.size = 48, this.showLockBadge = false});

  final BlockableAppModel app;
  final double size;
  final bool showLockBadge;

  static IconData iconFor(String appId) => switch (appId) {
    'tiktok' => FontAwesomeIcons.tiktok.data,
    'instagram' => FontAwesomeIcons.instagram.data,
    'x' => FontAwesomeIcons.xTwitter.data,
    'youtube' => FontAwesomeIcons.youtube.data,
    'snapchat' => FontAwesomeIcons.snapchat.data,
    'facebook' => FontAwesomeIcons.facebook.data,
    'reddit' => FontAwesomeIcons.reddit.data,
    'twitch' => FontAwesomeIcons.twitch.data,
    _ => Icons.apps_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isInstagram = app.id == 'instagram';
    final isSnapchat = app.id == 'snapchat';

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
            child: Icon(iconFor(app.id), color: isSnapchat ? Colors.black : Colors.white, size: size * 0.46),
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

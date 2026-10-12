// Renders the Sinkly Sink-Lock mark (SinklyLogoMarkPainter) to every PNG the
// stores and social profiles need — one vector source, crisp at each size.
//
// Run from the project root:
//   flutter test tool/brand_assets/generate_brand_assets_test.dart
// then strip the alpha channel from the iOS icons (App Store requirement):
//   python tool/brand_assets/flatten_ios_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/core/widgets/sinkly_logo_mark_painter.dart';

Future<void> _render(
  String path,
  int px, {
  SinklyLogoBackground background = SinklyLogoBackground.square,
  double glyphScale = 1,
  bool showGlyph = true,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  SinklyLogoMarkPainter(
    background: background,
    glyphScale: glyphScale,
    showGlyph: showGlyph,
  ).paint(canvas, Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  testWidgets('generate brand assets', (tester) async {
    await tester.runAsync(() async {
      // ── iOS: full-bleed square, the OS applies the rounded mask ──
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const iosIcons = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final entry in iosIcons.entries) {
        await _render('$ios/${entry.key}', entry.value);
      }

      // ── Android: legacy rounded icon + adaptive (API 26+) layers ──
      const res = 'android/app/src/main/res';
      const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
      for (final entry in densities.entries) {
        final dir = '$res/mipmap-${entry.key}';
        await _render('$dir/ic_launcher.png', (48 * entry.value).round(), background: SinklyLogoBackground.roundedTile);
        await _render(
          '$dir/ic_launcher_round.png',
          (48 * entry.value).round(),
          background: SinklyLogoBackground.circle,
          glyphScale: 0.84,
        );
        // Adaptive layers are 108 dp; the glyph stays inside the 66 dp safe zone.
        await _render(
          '$dir/ic_launcher_foreground.png',
          (108 * entry.value).round(),
          background: SinklyLogoBackground.none,
          glyphScale: 0.66,
        );
        // Backdrop only: the lock itself is in the foreground layer (no double glyph).
        await _render('$dir/ic_launcher_background.png', (108 * entry.value).round(), showGlyph: false);
      }

      // ── Brand kit: master icon + circular social avatars ──
      await _render('branding/sinkly_app_icon_1024.png', 1024, background: SinklyLogoBackground.roundedTile);
      await _render('branding/sinkly_app_icon_square_1024.png', 1024);
      for (final px in [1080, 400]) {
        await _render(
          'branding/social/sinkly_profile_circle_$px.png',
          px,
          background: SinklyLogoBackground.circle,
          glyphScale: 0.84,
        );
        // Square upload variant: platforms crop it to a circle themselves.
        await _render('branding/social/sinkly_profile_square_$px.png', px, glyphScale: 0.84);
      }
    });
  });
}

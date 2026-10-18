// Renders the heroine (the same code-drawn rig as the Flutter lock screen) to
// the PNG shown on the static lock card over a locked app:
//  • Android: android/app/src/main/res/drawable-nodpi/lock_heroine.png
//  • iOS shield icon: ios/SinklyShieldConfiguration/lock_heroine.png
//
// Run from the project root:
//   flutter test tool/brand_assets/generate_lock_heroine_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';

const _outputs = [
  'android/app/src/main/res/drawable-nodpi/lock_heroine.png',
  'ios/SinklyShieldConfiguration/lock_heroine.png',
];

void main() {
  testWidgets('generate lock heroine', (tester) async {
    const width = 220.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            // First act of the lock screen: she waves "Hey you! Caught you".
            child: const HeroineCharacterWidget(width: width, pose: HeroinePose.waveJoy),
          ),
        ),
      ),
    );
    // Let her settle into the pose.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      for (final path in _outputs) {
        File(path)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      }
      image.dispose();
    });
  });
}

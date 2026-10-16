import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sinkly/core/utils/functions/app_functions.dart';
import 'package:sinkly/core/widgets/app_toast_widget.dart';

/// Optional: `TOAST_SHOTS=<dir>` saves a PNG of each tone for visual review.
Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['TOAST_SHOTS'];
  if (dir == null) return;
  final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize, pixelRatio: 1 / tester.view.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadFonts() async {
  // google_fonts can't download in tests: register a real font under its names.
  final bytes = File('C:/Windows/Fonts/arial.ttf');
  if (!bytes.existsSync()) return;
  for (final family in ['PlusJakartaSans', 'Cairo', 'Roboto']) {
    for (final variant in ['regular', '500', '600', '700', '800']) {
      final name = variant == 'regular' && family == 'Roboto' ? family : '${family}_$variant';
      final loader = FontLoader(name)..addFont(Future.value(ByteData.view(bytes.readAsBytesSync().buffer)));
      await loader.load();
    }
  }
}

/// Animations need real frames: advance in small steps, not one big jump.
Future<void> _frames(WidgetTester tester, Duration total) async {
  for (var elapsed = Duration.zero; elapsed < total; elapsed += const Duration(milliseconds: 50)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  Future<BuildContext> pumpHost(WidgetTester tester, {TextDirection direction = TextDirection.ltr}) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(393, 852) * 2
      ..padding = const FakeViewPadding(top: 59 * 2, bottom: 34 * 2);
    addTearDown(tester.view.reset);
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(textDirection: direction, child: child!),
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold(backgroundColor: Color(0xFFEAF6FD));
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('shows centred text, then dismisses itself', (tester) async {
    final context = await pumpHost(tester);
    AppFunctions.showSnack(context, "We couldn't check your photo right now. Please try again.", tone: AppToastTone.error);
    await _frames(tester, const Duration(milliseconds: 900));

    final text = find.text("We couldn't check your photo right now. Please try again.");
    expect(text, findsOneWidget);
    expect(tester.widget<Text>(text).textAlign, TextAlign.center);
    // The card sits in the middle of the screen horizontally.
    expect(tester.getCenter(find.byType(AppToastWidget)).dx, closeTo(393 / 2, 1));
    // Fully visible once landed.
    final opacity = tester.widget<Opacity>(find.descendant(of: find.byType(AppToastWidget), matching: find.byType(Opacity)).first);
    expect(opacity.opacity, 1);
    await _shot(tester, 'toast_error_en');

    await _frames(tester, const Duration(seconds: 6));
    await _frames(tester, const Duration(milliseconds: 400));
    expect(text, findsNothing);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    final context = await pumpHost(tester);
    AppFunctions.showSnack(context, 'First');
    await _frames(tester, const Duration(milliseconds: 300));
    AppFunctions.showSnack(context, 'Second', tone: AppToastTone.success);
    await _frames(tester, const Duration(milliseconds: 900));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await _shot(tester, 'toast_success_en');
    await _frames(tester, const Duration(seconds: 6));
  });

  testWidgets('tap dismisses early', (tester) async {
    final context = await pumpHost(tester);
    AppFunctions.showSnack(context, 'Plan saved');
    await _frames(tester, const Duration(milliseconds: 900));
    await tester.tap(find.text('Plan saved'));
    await _frames(tester, const Duration(milliseconds: 400));
    expect(find.text('Plan saved'), findsNothing);
  });

  testWidgets('arabic, right-to-left', (tester) async {
    final context = await pumpHost(tester, direction: TextDirection.rtl);
    AppFunctions.showSnack(context, 'ما زالت هناك صحون في الحوض. اغسلها ثم صوّر مرة أخرى!', tone: AppToastTone.error);
    await _frames(tester, const Duration(milliseconds: 900));
    await _shot(tester, 'toast_error_ar');
    AppFunctions.showSnack(context, 'تم حفظ خطتك');
    await _frames(tester, const Duration(milliseconds: 900));
    await _shot(tester, 'toast_info_ar');
    await _frames(tester, const Duration(seconds: 6));
  });
}

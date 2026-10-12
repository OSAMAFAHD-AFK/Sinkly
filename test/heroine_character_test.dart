import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/commitment_heart_scene_widget.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_painter.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/heroine_character_widget.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

void main() {
  const poses = [
    HeroinePose.idle,
    HeroinePose.curious,
    HeroinePose.meh,
    HeroinePose.worried,
    HeroinePose.overwhelmed,
    HeroinePose.wave,
    HeroinePose.waveJoy,
    HeroinePose.scroll,
    HeroinePose.scrollGuilty,
    HeroinePose.washSad,
    HeroinePose.washJoy,
    HeroinePose.sleepy,
    HeroinePose.cheer,
    HeroinePose.cherish,
    HeroinePose.cherishJoy,
    HeroinePose.present,
    HeroinePose.presentJoy,
    HeroinePose.encourage,
    HeroinePose.joyJump,
    HeroinePose.adore,
    HeroinePose.clapHappy,
  ];

  testWidgets('heroine paints every pose × motion × prop without errors', (tester) async {
    for (final prop in HeroineProp.values) {
      for (final motion in HeroineMotion.values) {
        for (final pose in poses) {
          await tester.pumpWidget(_host(HeroineCharacterWidget(pose: pose, motion: motion, prop: prop)));
          await tester.pump(const Duration(milliseconds: 700));
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('heroine blends between poses and mirrors in RTL', (tester) async {
    await tester.pumpWidget(_host(const HeroineCharacterWidget(pose: HeroinePose.idle), direction: TextDirection.rtl));
    await tester.pumpWidget(
      _host(
        const HeroineCharacterWidget(pose: HeroinePose.cheer, motion: HeroineMotion.cheer),
        direction: TextDirection.rtl,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(HeroineCharacterWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('commitment heart scene follows hold progress and celebrates', (tester) async {
    final progress = ValueNotifier<double>(0);
    await tester.pumpWidget(_host(CommitmentHeartSceneWidget(holdProgress: progress, committed: false)));
    for (final value in [0.25, 0.5, 0.75, 1.0]) {
      progress.value = value;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(_host(CommitmentHeartSceneWidget(holdProgress: progress, committed: true)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    // Unmount to stop repeating animations before the test ends.
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
  });
}

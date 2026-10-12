// TEMP (deleted after review): captures paywall hero frames for visual QA.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/presentation/views/widgets/paywall_heroine_hero_widget.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/data_sources/subscription_remote_data_source.dart';
import 'package:sinkly/Features/Feature_04_Subscription/data/repos/subscription_repo_impl.dart';
import 'package:sinkly/Features/Feature_04_Subscription/presentation/manager/subscription_cubit.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

const _out = String.fromEnvironment('OUT');

Future<void> _font(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final w in ['regular', '500', '600', '700', '800']) {
      await _font('PlusJakartaSans_$w', w == 'regular' || w == '500' ? 'C:/Windows/Fonts/arial.ttf' : 'C:/Windows/Fonts/arialbd.ttf');
    }
  });

  testWidgets('frames', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 260);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    final cubit = SubscriptionCubit(SubscriptionRepoImpl(MockSubscriptionRemoteDataSource(storage)));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
        home: BlocProvider.value(
          value: cubit..initialize(),
          child: const Scaffold(
            backgroundColor: Color(0xFFEAF5FC),
            body: Padding(padding: EdgeInsets.fromLTRB(22, 30, 22, 0), child: PaywallHeroineHeroWidget(celebrating: false)),
          ),
        ),
      ),
    );

    var n = 0;
    Future<void> shot(String label) async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      await tester.runAsync(() async {
        final image = await layer.toImage(const Rect.fromLTWH(0, 0, 393, 260));
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/${(n++).toString().padLeft(2, '0')}_$label.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    Future<void> run(String label, int ms, {int every = 150}) async {
      for (var t = 0; t < ms; t += every) {
        await tester.pump(Duration(milliseconds: every));
        await shot('${label}_${t + every}ms');
      }
    }

    await shot('loading');
    await tester.pump(const Duration(milliseconds: 400)); // plans load → annual selected
    await run('annual_joy', 1950, every: 130);
    await run('annual_settled', 1200, every: 400);
    cubit.selectPlan(cubit.state.plans.firstWhere((p) => !p.isBestValue));
    await run('monthly_clap', 1500, every: 125);
    await run('monthly_settled', 1200, every: 400);
    await tester.pump(const Duration(seconds: 3));
    await run('nudge_wave', 900, every: 300);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    await cubit.close();
  });
}

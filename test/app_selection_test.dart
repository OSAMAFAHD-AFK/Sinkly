import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import 'package:sinkly/core/models/shared_core_models.dart';

void main() {
  final apps = MethodChannelInstalledAppsDataSource.sampleApps;
  final social = apps.where((a) => a.category == AppCategory.social).toList();
  BlockableAppModel app(String id) => apps.firstWhere((a) => a.id == id);

  setUpAll(() => BlockableAppModel.registerInstalled(apps));

  test('Android categories map to Screen-Time groups (+ known packages)', () {
    expect(AppCategory.fromAndroid(0, 'x.y'), AppCategory.games);
    expect(AppCategory.fromAndroid(2, 'x.y'), AppCategory.entertainment);
    expect(AppCategory.fromAndroid(-1, 'com.zhiliaoapp.musically'), AppCategory.social);
    expect(AppCategory.fromAndroid(-1, 'com.unknown.thing'), AppCategory.other);
  });

  test('selecting a category covers all its apps and drops redundant picks', () {
    final selection = const AppSelectionModel(appIds: ['tiktok', 'youtube']).toggleCategory(AppCategory.social);
    expect(selection.categoryIds, ['social']);
    expect(selection.appIds, ['youtube']); // tiktok is covered by the category now
    expect(social.every(selection.isAppSelected), isTrue);
    expect(selection.selectedCount(apps), social.length + 1);
  });

  test('unticking one app breaks the category into its remaining apps', () {
    final selection = const AppSelectionModel().toggleCategory(AppCategory.social).toggleApp(app('tiktok'), apps);
    expect(selection.categoryIds, isEmpty);
    expect(selection.isAppSelected(app('tiktok')), isFalse);
    expect(selection.selectedInCategory(AppCategory.social, apps), social.length - 1);
  });

  test('"All apps & categories" toggles every present category', () {
    final all = const AppSelectionModel().toggleAll(apps);
    expect(all.isAllSelected(apps), isTrue);
    expect(all.selectedCount(apps), apps.length);
    expect(all.toggleAll(apps).isEmpty, isTrue);
  });

  test('plan resolves explicit apps + installed apps of selected categories', () {
    final plan = UserPlanModel.initial().withAppSelection(
      const AppSelectionModel(appIds: ['com.duolingo'], categoryIds: ['games']),
    );
    final ids = plan.blockedApps.map((a) => a.id).toSet();
    expect(ids, containsAll(['com.duolingo', 'com.roblox.client', 'com.king.candycrushsaga']));
    expect(UserPlanModel.fromJson(plan.toJson()).appSelection, plan.appSelection);
  });

  test('iOS picks count toward the selection', () {
    const selection = AppSelectionModel(systemPickerCount: 3);
    expect(selection.isEmpty, isFalse);
    expect(selection.selectedCount(const []), 3);
  });
}

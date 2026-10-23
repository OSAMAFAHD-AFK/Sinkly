import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:sinkly/Features/Feature_02_Onboarding/data/repos/onboarding_repo_impl.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import 'package:sinkly/Features/Feature_09_Settings/data/data_sources/store_review_platform_data_source.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

class _FakeStoreReview implements StoreReviewPlatformDataSource {
  int nativeRequests = 0;
  bool failNative = false;

  @override
  Future<void> requestNativeReview() async {
    nativeRequests++;
    if (failNative) throw Exception('no store');
  }

  @override
  Future<StoreReviewOutcome> openStoreReviewPage() async => StoreReviewOutcome.storePage;
}

/// Not used by these tests.
class _NoInstalledApps implements InstalledAppsPlatformDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({OnboardingRepoImpl repo, _FakeStoreReview review})> setUp() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    final review = _FakeStoreReview();
    final repo = OnboardingRepoImpl(
      localDataSource: OnboardingLocalDataSourceImpl(storage),
      permissionsDataSource: MockDevicePermissionsDataSource(),
      installedAppsDataSource: _NoInstalledApps(),
      storeReviewDataSource: review,
    );
    return (repo: repo, review: review);
  }

  test('onboarding asks for the native rating sheet once per install', () async {
    final s = await setUp();
    await s.repo.requestStoreReviewOnce();
    await s.repo.requestStoreReviewOnce(); // e.g. app restarted on the plan step
    expect(s.review.nativeRequests, 1);
  });

  test('a store error never reaches the user', () async {
    final s = await setUp();
    s.review.failNative = true;
    await expectLater(s.repo.requestStoreReviewOnce(), completes);
  });
}

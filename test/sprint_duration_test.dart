import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_capture_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_verification_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/sink_session_local_data_source.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/repos/sink_unlock_repo_impl.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/presentation/manager/sink_unlock_cubit.dart';
import 'package:sinkly/core/utils/app_constants.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

class _NoCapture implements SinkPhotoCaptureDataSource {
  @override
  Future<String?> captureSinkPhoto() async => null;
}

SinkUnlockCubit _cubit(LocalStorageService storage) => SinkUnlockCubit(
  SinkUnlockRepoImpl(
    sessionDataSource: SinkSessionLocalDataSourceImpl(storage),
    captureDataSource: _NoCapture(),
    verificationDataSource: MockSinkPhotoVerificationDataSource(),
    blockingDataSource: MockAppBlockingPlatformDataSource(),
  ),
);

void main() {
  test('default sprint is 5 minutes', () {
    expect(AppConstants.sinkSprintDuration, const Duration(minutes: 5));
  });

  test('user can adjust the timer before and during the sprint; choice persists', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    final cubit = _cubit(storage);

    expect(cubit.state.sprintMinutes, 5);
    expect(cubit.state.remainingSeconds, 300);

    await cubit.setSprintMinutes(10);
    expect(cubit.state.sprintTotalSeconds, 600);
    expect(cubit.state.remainingSeconds, 600);
    expect(storage.plan.sprintMinutes, 10);

    cubit.startSprint();
    await cubit.setSprintMinutes(15); // more time while running
    expect(cubit.state.sprintTotalSeconds, 900);
    expect(cubit.state.remainingSeconds, inInclusiveRange(898, 900));

    await cubit.setSprintMinutes(999); // clamped to the max
    expect(cubit.state.sprintMinutes, AppConstants.maxSprintMinutes);
    await cubit.setSprintMinutes(0); // clamped to the min
    expect(cubit.state.sprintMinutes, AppConstants.minSprintMinutes);

    await cubit.close();
    // A new session starts with the saved preference.
    final next = _cubit(storage);
    expect(next.state.sprintMinutes, AppConstants.minSprintMinutes);
    await next.close();
  });
}

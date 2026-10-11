import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../data_sources/app_blocking_platform_data_source.dart';
import '../data_sources/sink_photo_capture_data_source.dart';
import '../data_sources/sink_photo_verification_data_source.dart';
import '../data_sources/sink_session_local_data_source.dart';
import '../models/sink_photo_verification_result_model.dart';
import 'sink_unlock_repo.dart';

class SinkUnlockRepoImpl implements SinkUnlockRepo {
  SinkUnlockRepoImpl({
    required SinkSessionLocalDataSource sessionDataSource,
    required SinkPhotoCaptureDataSource captureDataSource,
    required SinkPhotoVerificationDataSource verificationDataSource,
    required AppBlockingPlatformDataSource blockingDataSource,
  }) : _sessions = sessionDataSource,
       _capture = captureDataSource,
       _verification = verificationDataSource,
       _blocking = blockingDataSource;

  final SinkSessionLocalDataSource _sessions;
  final SinkPhotoCaptureDataSource _capture;
  final SinkPhotoVerificationDataSource _verification;
  final AppBlockingPlatformDataSource _blocking;

  @override
  LockStatusModel currentLockStatus({required DateTime now}) =>
      LockStatusModel.evaluate(plan: _sessions.readPlan(), sessions: _sessions.readSessions(), now: now);

  @override
  List<BlockableAppModel> blockedApps() => _sessions.readPlan().blockedApps;

  @override
  SinkProgressStatsModel progressStats({required DateTime now}) =>
      SinkProgressStatsModel.fromSessions(_sessions.readSessions(), now: now);

  @override
  Future<Either<Failure, String?>> captureSinkPhoto() async {
    try {
      return right(await _capture.captureSinkPhoto());
    } catch (error) {
      return left(PermissionFailure('error_camera', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, SinkPhotoVerificationResultModel>> verifySinkPhoto(String photoPath) async {
    try {
      final result = await _verification.verifySinkPhoto(photoPath);
      if (!result.isClean) return left(VerificationFailure(result.reasonKey ?? 'verify_error_not_clean'));
      return right(result);
    } catch (error) {
      return left(VerificationFailure('verify_error_unreadable', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, SinkCleaningSessionModel>> completeSession({
    required DateTime startedAt,
    required String photoPath,
    required MealType? triggeringMeal,
  }) async {
    try {
      final now = DateTime.now();
      final session = SinkCleaningSessionModel(
        id: 'sink_${now.microsecondsSinceEpoch}',
        startedAt: startedAt,
        completedAt: now,
        triggeringMeal: triggeringMeal,
        photoPath: photoPath,
      );
      await _sessions.saveSession(session);
      await _blocking.unlockApps(blockedApps());
      return right(session);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

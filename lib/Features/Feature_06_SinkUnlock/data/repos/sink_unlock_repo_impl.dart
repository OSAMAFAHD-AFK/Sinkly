import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/crash_reporting_service.dart';
import '../data_sources/connectivity_probe_data_source.dart';
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
    required ConnectivityProbeDataSource connectivityDataSource,
  }) : _sessions = sessionDataSource,
       _capture = captureDataSource,
       _verification = verificationDataSource,
       _connectivity = connectivityDataSource;

  final SinkSessionLocalDataSource _sessions;
  final SinkPhotoCaptureDataSource _capture;
  final SinkPhotoVerificationDataSource _verification;
  final ConnectivityProbeDataSource _connectivity;

  @override
  Future<bool> hasInternet() => _connectivity.hasInternet();

  @override
  LockStatusModel currentLockStatus({required DateTime now}) =>
      LockStatusModel.evaluate(plan: _sessions.readPlan(), sessions: _sessions.readSessions(), now: now);

  @override
  List<BlockableAppModel> blockedApps() => _sessions.readPlan().blockedApps;

  @override
  String userName() => _sessions.readPlan().userName.trim();

  @override
  int sprintMinutes() => _sessions.readPlan().sprintMinutes;

  @override
  Future<void> saveSprintMinutes(int minutes) => _sessions.saveSprintMinutes(minutes);

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
    } on VerificationUnavailableException catch (error) {
      // The user only sees a friendly message (offline, daily limit… are normal).
      return left(VerificationFailure(error.messageKey, debugMessage: error.debugMessage));
    } catch (error, stack) {
      // A real bug: reported to Crashlytics (no photo, no personal data).
      CrashReportingService.recordError(error, stack, reason: 'photo check');
      return left(VerificationFailure('verify_error_unreadable', debugMessage: '$error'));
    } finally {
      // Whatever the answer: the photo has done its job and is deleted.
      await _capture.discardSinkPhoto(photoPath);
    }
  }

  @override
  Future<Either<Failure, SinkCleaningSessionModel>> completeSession({
    required DateTime startedAt,
    required MealType? triggeringMeal,
  }) async {
    try {
      final now = DateTime.now();
      final session = SinkCleaningSessionModel(
        id: 'sink_${now.microsecondsSinceEpoch}',
        startedAt: startedAt,
        completedAt: now,
        triggeringMeal: triggeringMeal,
      );
      // Saving the session IS the unlock: AppBlockingRepo sees it and tells
      // the native blocker at once.
      await _sessions.saveSession(session);
      return right(session);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/shared_core_models.dart';
import '../models/sink_photo_verification_result_model.dart';

abstract class SinkUnlockRepo {
  LockStatusModel currentLockStatus({required DateTime now});
  List<BlockableAppModel> blockedApps();

  /// First name from onboarding ('' when skipped) — the heroine uses it.
  String userName();

  /// The user's preferred sprint length (minutes).
  int sprintMinutes();
  Future<void> saveSprintMinutes(int minutes);
  SinkProgressStatsModel progressStats({required DateTime now});

  /// `Right(null)` means the user cancelled the camera.
  Future<Either<Failure, String?>> captureSinkPhoto();

  Future<Either<Failure, SinkPhotoVerificationResultModel>> verifySinkPhoto(String photoPath);

  /// Records the session and lifts the OS-level lock.
  Future<Either<Failure, SinkCleaningSessionModel>> completeSession({
    required DateTime startedAt,
    required MealType? triggeringMeal,
  });

  /// Real internet available? Checked before the camera opens.
  Future<bool> hasInternet();
}

import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

/// Everything the lock overlay shows, captured at the moment a locked app
/// was opened.
class LockOverlaySnapshotModel extends Equatable {
  const LockOverlaySnapshotModel({
    required this.lockStatus,
    required this.userName,
    required this.sprintMinutes,
    required this.currentStreakDays,
    this.attemptedApp,
  });

  final LockStatusModel lockStatus;
  final String userName;
  final int sprintMinutes;
  final int currentStreakDays;

  /// The app the user just tried to open. Null when unknown (iOS keeps app
  /// tokens native-side, and the in-app preview may have no apps selected).
  final BlockableAppModel? attemptedApp;

  /// Null while locked means the lock was triggered manually ("Test lock").
  MealType? get lockingMeal => lockStatus.lockingMeal;

  @override
  List<Object?> get props => [lockStatus, userName, sprintMinutes, currentStreakDays, attemptedApp];
}

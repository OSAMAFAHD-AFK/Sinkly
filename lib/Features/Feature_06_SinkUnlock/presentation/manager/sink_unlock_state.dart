part of 'sink_unlock_cubit.dart';

/// Linear flow of the unlock experience.
enum SinkUnlockStage { sprinting, verifying, celebrating }

class SinkUnlockState extends Equatable {
  const SinkUnlockState({
    required this.stage,
    required this.lockStatus,
    required this.blockedApps,
    required this.remainingSeconds,
    required this.sprintTotalSeconds,
    this.userName = '',
    this.sprintStartedAt,
    this.photoPath,
    this.isCapturing = false,
    this.failureKey,
    this.completedSession,
    this.statsAfterUnlock,
  });

  final SinkUnlockStage stage;
  final LockStatusModel lockStatus;
  final List<BlockableAppModel> blockedApps;
  final int remainingSeconds;

  /// Length of this sprint in seconds (user-adjustable).
  final int sprintTotalSeconds;
  final String userName;
  final DateTime? sprintStartedAt;
  final String? photoPath;
  final bool isCapturing;
  final String? failureKey;
  final SinkCleaningSessionModel? completedSession;
  final SinkProgressStatsModel? statsAfterUnlock;

  int get sprintMinutes => (sprintTotalSeconds / 60).round();

  /// 0 → 1 as the sprint elapses.
  double get sprintProgress => 1 - remainingSeconds / sprintTotalSeconds;

  bool get isSprintFinished => remainingSeconds <= 0;

  SinkUnlockState copyWith({
    SinkUnlockStage? stage,
    LockStatusModel? lockStatus,
    List<BlockableAppModel>? blockedApps,
    int? remainingSeconds,
    int? sprintTotalSeconds,
    DateTime? sprintStartedAt,
    String? photoPath,
    bool? isCapturing,
    String? failureKey,
    bool clearFailure = false,
    SinkCleaningSessionModel? completedSession,
    SinkProgressStatsModel? statsAfterUnlock,
  }) => SinkUnlockState(
    stage: stage ?? this.stage,
    lockStatus: lockStatus ?? this.lockStatus,
    blockedApps: blockedApps ?? this.blockedApps,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    sprintTotalSeconds: sprintTotalSeconds ?? this.sprintTotalSeconds,
    userName: userName,
    sprintStartedAt: sprintStartedAt ?? this.sprintStartedAt,
    photoPath: photoPath ?? this.photoPath,
    isCapturing: isCapturing ?? this.isCapturing,
    failureKey: clearFailure ? null : failureKey ?? this.failureKey,
    completedSession: completedSession ?? this.completedSession,
    statsAfterUnlock: statsAfterUnlock ?? this.statsAfterUnlock,
  );

  @override
  List<Object?> get props => [
    stage,
    lockStatus,
    blockedApps,
    remainingSeconds,
    sprintTotalSeconds,
    userName,
    sprintStartedAt,
    photoPath,
    isCapturing,
    failureKey,
    completedSession,
    statsAfterUnlock,
  ];
}

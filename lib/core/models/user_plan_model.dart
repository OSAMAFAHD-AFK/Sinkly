import 'package:equatable/equatable.dart';

import 'blockable_app_model.dart';
import 'weekly_lock_schedule_model.dart';

/// Everything the user configured during onboarding (and later in the Plan
/// tab). Persisted locally today; ready to be mirrored to Firestore later.
class UserPlanModel extends Equatable {
  const UserPlanModel({
    required this.userName,
    required this.languageCode,
    required this.schedule,
    required this.blockedAppIds,
    this.dishPileupSeverityId,
    this.mainStruggleId,
    this.onboardingCompleted = false,
    this.screenTimePermissionGranted = false,
    this.notificationsEnabled = true,
    this.manualLockTriggeredAt,
  });

  final String userName;
  final String languageCode;
  final WeeklyLockScheduleModel schedule;
  final List<String> blockedAppIds;

  /// Quiz answers kept for personalization & analytics segmentation.
  final String? dishPileupSeverityId;
  final String? mainStruggleId;

  final bool onboardingCompleted;
  final bool screenTimePermissionGranted;
  final bool notificationsEnabled;

  /// Set when the user taps "Test the lock now" — behaves like a meal ending.
  final DateTime? manualLockTriggeredAt;

  factory UserPlanModel.initial({String languageCode = 'en'}) => UserPlanModel(
    userName: '',
    languageCode: languageCode,
    schedule: WeeklyLockScheduleModel.initial(),
    blockedAppIds: BlockableAppModel.defaultSelectedIds,
  );

  List<BlockableAppModel> get blockedApps => BlockableAppModel.fromIds(blockedAppIds);

  String get displayName => userName.trim().isEmpty ? '' : userName.trim();

  /// Product promise: ~1 hour of avoidance scrolling reclaimed per active day.
  int get estimatedHoursReclaimedPerWeek => schedule.activeWeekdays.length;

  static const Object _unset = Object();

  UserPlanModel copyWith({
    String? userName,
    String? languageCode,
    WeeklyLockScheduleModel? schedule,
    List<String>? blockedAppIds,
    String? dishPileupSeverityId,
    String? mainStruggleId,
    bool? onboardingCompleted,
    bool? screenTimePermissionGranted,
    bool? notificationsEnabled,
    Object? manualLockTriggeredAt = _unset,
  }) => UserPlanModel(
    userName: userName ?? this.userName,
    languageCode: languageCode ?? this.languageCode,
    schedule: schedule ?? this.schedule,
    blockedAppIds: blockedAppIds ?? this.blockedAppIds,
    dishPileupSeverityId: dishPileupSeverityId ?? this.dishPileupSeverityId,
    mainStruggleId: mainStruggleId ?? this.mainStruggleId,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    screenTimePermissionGranted: screenTimePermissionGranted ?? this.screenTimePermissionGranted,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    manualLockTriggeredAt: identical(manualLockTriggeredAt, _unset)
        ? this.manualLockTriggeredAt
        : manualLockTriggeredAt as DateTime?,
  );

  factory UserPlanModel.fromJson(Map<String, dynamic> json) => UserPlanModel(
    userName: json['userName'] as String? ?? '',
    languageCode: json['languageCode'] as String? ?? 'en',
    schedule: json['schedule'] is Map
        ? WeeklyLockScheduleModel.fromJson(Map<String, dynamic>.from(json['schedule'] as Map))
        : WeeklyLockScheduleModel.initial(),
    blockedAppIds: List<String>.unmodifiable((json['blockedAppIds'] as List?)?.cast<String>() ?? const <String>[]),
    dishPileupSeverityId: json['dishPileupSeverityId'] as String?,
    mainStruggleId: json['mainStruggleId'] as String?,
    onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    screenTimePermissionGranted: json['screenTimePermissionGranted'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    manualLockTriggeredAt: DateTime.tryParse(json['manualLockTriggeredAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'languageCode': languageCode,
    'schedule': schedule.toJson(),
    'blockedAppIds': blockedAppIds,
    'dishPileupSeverityId': dishPileupSeverityId,
    'mainStruggleId': mainStruggleId,
    'onboardingCompleted': onboardingCompleted,
    'screenTimePermissionGranted': screenTimePermissionGranted,
    'notificationsEnabled': notificationsEnabled,
    'manualLockTriggeredAt': manualLockTriggeredAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    userName,
    languageCode,
    schedule,
    blockedAppIds,
    dishPileupSeverityId,
    mainStruggleId,
    onboardingCompleted,
    screenTimePermissionGranted,
    notificationsEnabled,
    manualLockTriggeredAt,
  ];
}

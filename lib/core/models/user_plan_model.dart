import 'package:equatable/equatable.dart';

import '../utils/app_constants.dart';
import 'app_selection_model.dart';
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
    this.blockedCategoryIds = const [],
    this.systemPickerCount = 0,
    this.dishPileupSeverityId,
    this.mainStruggleId,
    this.onboardingCompleted = false,
    this.screenTimePermissionGranted = false,
    this.notificationsEnabled = true,
    this.manualLockTriggeredAt,
    this.lockingActiveSince,
    this.sprintMinutes = _defaultSprintMinutes,
  });

  final String userName;
  final String languageCode;
  final WeeklyLockScheduleModel schedule;
  final List<String> blockedAppIds;

  /// Whole categories locked (also covers apps installed later).
  final List<String> blockedCategoryIds;

  /// iOS: apps + categories chosen in Apple's picker (tokens stored natively).
  final int systemPickerCount;

  /// Quiz answers kept for personalization & analytics segmentation.
  final String? dishPileupSeverityId;
  final String? mainStruggleId;

  final bool onboardingCompleted;
  final bool screenTimePermissionGranted;
  final bool notificationsEnabled;

  /// A lock that behaves like a meal ending right now. Nothing in the UI sets
  /// it any more (the "Test the lock now" button was removed); kept because
  /// saved plans and the native blockers still read it. Saving the plan clears it.
  final DateTime? manualLockTriggeredAt;

  /// When app locking (re)started: onboarding done + subscription active.
  /// Meals that ended before this moment never lock. `null` = locking off
  /// (no subscription yet, or it lapsed — the plan itself is kept).
  final DateTime? lockingActiveSince;

  /// How long the user's sink sprint timer runs (adjustable in the unlock flow).
  final int sprintMinutes;

  static const int _defaultSprintMinutes = 5; // = AppConstants.sinkSprintDuration

  factory UserPlanModel.initial({String languageCode = 'en'}) => UserPlanModel(
    userName: '',
    languageCode: languageCode,
    schedule: WeeklyLockScheduleModel.initial(),
    blockedAppIds: BlockableAppModel.defaultSelectedIds,
  );

  /// Every app covered by the selection (explicit apps + selected categories).
  List<BlockableAppModel> get blockedApps =>
      BlockableAppModel.resolveSelection(appIds: blockedAppIds, categoryIds: blockedCategoryIds);

  AppSelectionModel get appSelection =>
      AppSelectionModel(appIds: blockedAppIds, categoryIds: blockedCategoryIds, systemPickerCount: systemPickerCount);

  UserPlanModel withAppSelection(AppSelectionModel selection) => copyWith(
    blockedAppIds: selection.appIds,
    blockedCategoryIds: selection.categoryIds,
    systemPickerCount: selection.systemPickerCount,
  );

  String get displayName => userName.trim().isEmpty ? '' : userName.trim();

  /// Product promise: ~1 hour of avoidance scrolling reclaimed per active day.
  int get estimatedHoursReclaimedPerWeek => schedule.activeWeekdays.length;

  static const Object _unset = Object();

  UserPlanModel copyWith({
    String? userName,
    String? languageCode,
    WeeklyLockScheduleModel? schedule,
    List<String>? blockedAppIds,
    List<String>? blockedCategoryIds,
    int? systemPickerCount,
    String? dishPileupSeverityId,
    String? mainStruggleId,
    bool? onboardingCompleted,
    bool? screenTimePermissionGranted,
    bool? notificationsEnabled,
    Object? manualLockTriggeredAt = _unset,
    Object? lockingActiveSince = _unset,
    int? sprintMinutes,
  }) => UserPlanModel(
    userName: userName ?? this.userName,
    languageCode: languageCode ?? this.languageCode,
    schedule: schedule ?? this.schedule,
    blockedAppIds: blockedAppIds ?? this.blockedAppIds,
    blockedCategoryIds: blockedCategoryIds ?? this.blockedCategoryIds,
    systemPickerCount: systemPickerCount ?? this.systemPickerCount,
    dishPileupSeverityId: dishPileupSeverityId ?? this.dishPileupSeverityId,
    mainStruggleId: mainStruggleId ?? this.mainStruggleId,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    screenTimePermissionGranted: screenTimePermissionGranted ?? this.screenTimePermissionGranted,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    manualLockTriggeredAt: identical(manualLockTriggeredAt, _unset)
        ? this.manualLockTriggeredAt
        : manualLockTriggeredAt as DateTime?,
    lockingActiveSince: identical(lockingActiveSince, _unset)
        ? this.lockingActiveSince
        : lockingActiveSince as DateTime?,
    sprintMinutes: sprintMinutes ?? this.sprintMinutes,
  );

  factory UserPlanModel.fromJson(Map<String, dynamic> json) => UserPlanModel(
    userName: json['userName'] as String? ?? '',
    languageCode: json['languageCode'] as String? ?? 'en',
    schedule: json['schedule'] is Map
        ? WeeklyLockScheduleModel.fromJson(Map<String, dynamic>.from(json['schedule'] as Map))
        : WeeklyLockScheduleModel.initial(),
    blockedAppIds: List<String>.unmodifiable((json['blockedAppIds'] as List?)?.cast<String>() ?? const <String>[]),
    blockedCategoryIds: List<String>.unmodifiable(
      (json['blockedCategoryIds'] as List?)?.cast<String>() ?? const <String>[],
    ),
    systemPickerCount: (json['systemPickerCount'] as num?)?.toInt() ?? 0,
    dishPileupSeverityId: json['dishPileupSeverityId'] as String?,
    mainStruggleId: json['mainStruggleId'] as String?,
    onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    screenTimePermissionGranted: json['screenTimePermissionGranted'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    manualLockTriggeredAt: DateTime.tryParse(json['manualLockTriggeredAt'] as String? ?? ''),
    lockingActiveSince: DateTime.tryParse(json['lockingActiveSince'] as String? ?? ''),
    sprintMinutes: ((json['sprintMinutes'] as num?)?.toInt() ?? _defaultSprintMinutes).clamp(
      AppConstants.minSprintMinutes,
      AppConstants.maxSprintMinutes,
    ),
  );

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'languageCode': languageCode,
    'schedule': schedule.toJson(),
    'blockedAppIds': blockedAppIds,
    'blockedCategoryIds': blockedCategoryIds,
    'systemPickerCount': systemPickerCount,
    'dishPileupSeverityId': dishPileupSeverityId,
    'mainStruggleId': mainStruggleId,
    'onboardingCompleted': onboardingCompleted,
    'screenTimePermissionGranted': screenTimePermissionGranted,
    'notificationsEnabled': notificationsEnabled,
    'manualLockTriggeredAt': manualLockTriggeredAt?.toIso8601String(),
    'lockingActiveSince': lockingActiveSince?.toIso8601String(),
    'sprintMinutes': sprintMinutes,
  };

  @override
  List<Object?> get props => [
    userName,
    languageCode,
    schedule,
    blockedAppIds,
    blockedCategoryIds,
    systemPickerCount,
    dishPileupSeverityId,
    mainStruggleId,
    onboardingCompleted,
    screenTimePermissionGranted,
    notificationsEnabled,
    manualLockTriggeredAt,
    lockingActiveSince,
    sprintMinutes,
  ];
}

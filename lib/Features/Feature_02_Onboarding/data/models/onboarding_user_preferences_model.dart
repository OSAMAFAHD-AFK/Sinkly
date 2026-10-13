import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

/// Immutable draft of every answer collected across the 15-step funnel.
/// Converted into the persisted [UserPlanModel] when onboarding completes.
class OnboardingUserPreferencesModel extends Equatable {
  const OnboardingUserPreferencesModel({
    required this.languageCode,
    required this.userName,
    required this.schedule,
    required this.appSelection,
    this.dishPileupSeverityId,
    this.mainStruggleId,
    this.screenTimePermissionGranted = false,
    this.notificationsAccepted = false,
    this.commitmentConfirmed = false,
  });

  final String languageCode;
  final String userName;
  final String? dishPileupSeverityId;
  final String? mainStruggleId;
  final WeeklyLockScheduleModel schedule;

  /// Apps / categories to lock (screen 10).
  final AppSelectionModel appSelection;
  List<String> get blockedAppIds => appSelection.appIds;
  final bool screenTimePermissionGranted;
  final bool notificationsAccepted;
  final bool commitmentConfirmed;

  factory OnboardingUserPreferencesModel.initial({required String languageCode}) => OnboardingUserPreferencesModel(
    languageCode: languageCode,
    userName: '',
    schedule: WeeklyLockScheduleModel.initial(),
    appSelection: const AppSelectionModel(appIds: BlockableAppModel.defaultSelectedIds),
  );

  /// Resume a partially completed onboarding from the saved plan.
  factory OnboardingUserPreferencesModel.fromUserPlan(UserPlanModel plan, {required String languageCode}) =>
      OnboardingUserPreferencesModel(
        languageCode: languageCode,
        userName: plan.userName,
        dishPileupSeverityId: plan.dishPileupSeverityId,
        mainStruggleId: plan.mainStruggleId,
        schedule: plan.schedule,
        appSelection: plan.appSelection,
        screenTimePermissionGranted: plan.screenTimePermissionGranted,
        notificationsAccepted: plan.notificationsEnabled,
      );

  String get trimmedName => userName.trim();

  UserPlanModel toUserPlan({required bool onboardingCompleted}) => UserPlanModel(
    userName: trimmedName,
    languageCode: languageCode,
    schedule: schedule,
    blockedAppIds: appSelection.appIds,
    blockedCategoryIds: appSelection.categoryIds,
    systemPickerCount: appSelection.systemPickerCount,
    dishPileupSeverityId: dishPileupSeverityId,
    mainStruggleId: mainStruggleId,
    onboardingCompleted: onboardingCompleted,
    screenTimePermissionGranted: screenTimePermissionGranted,
    notificationsEnabled: notificationsAccepted,
  );

  OnboardingUserPreferencesModel copyWith({
    String? languageCode,
    String? userName,
    String? dishPileupSeverityId,
    String? mainStruggleId,
    WeeklyLockScheduleModel? schedule,
    AppSelectionModel? appSelection,
    bool? screenTimePermissionGranted,
    bool? notificationsAccepted,
    bool? commitmentConfirmed,
  }) => OnboardingUserPreferencesModel(
    languageCode: languageCode ?? this.languageCode,
    userName: userName ?? this.userName,
    dishPileupSeverityId: dishPileupSeverityId ?? this.dishPileupSeverityId,
    mainStruggleId: mainStruggleId ?? this.mainStruggleId,
    schedule: schedule ?? this.schedule,
    appSelection: appSelection ?? this.appSelection,
    screenTimePermissionGranted: screenTimePermissionGranted ?? this.screenTimePermissionGranted,
    notificationsAccepted: notificationsAccepted ?? this.notificationsAccepted,
    commitmentConfirmed: commitmentConfirmed ?? this.commitmentConfirmed,
  );

  @override
  List<Object?> get props => [
    languageCode,
    userName,
    dishPileupSeverityId,
    mainStruggleId,
    schedule,
    appSelection,
    screenTimePermissionGranted,
    notificationsAccepted,
    commitmentConfirmed,
  ];
}

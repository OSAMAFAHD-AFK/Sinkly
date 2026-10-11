import 'package:equatable/equatable.dart';

import '../../../../core/models/user_plan_model.dart';

/// The subset of user data the Settings screen shows & edits.
class SettingsPreferencesModel extends Equatable {
  const SettingsPreferencesModel({
    required this.userName,
    required this.languageCode,
    required this.notificationsEnabled,
    required this.screenTimePermissionGranted,
  });

  final String userName;
  final String languageCode;
  final bool notificationsEnabled;
  final bool screenTimePermissionGranted;

  factory SettingsPreferencesModel.fromPlan(UserPlanModel plan, {required String languageCode}) =>
      SettingsPreferencesModel(
        userName: plan.displayName,
        languageCode: languageCode,
        notificationsEnabled: plan.notificationsEnabled,
        screenTimePermissionGranted: plan.screenTimePermissionGranted,
      );

  @override
  List<Object?> get props => [userName, languageCode, notificationsEnabled, screenTimePermissionGranted];
}

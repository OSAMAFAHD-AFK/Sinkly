part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.preferences, this.isRequestingPermission = false, this.failureKey});

  final SettingsPreferencesModel preferences;
  final bool isRequestingPermission;
  final String? failureKey;

  SettingsState copyWith({SettingsPreferencesModel? preferences, bool? isRequestingPermission, String? failureKey}) =>
      SettingsState(
        preferences: preferences ?? this.preferences,
        isRequestingPermission: isRequestingPermission ?? this.isRequestingPermission,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props => [preferences, isRequestingPermission, failureKey];
}

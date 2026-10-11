import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/settings_preferences_model.dart';

abstract class SettingsRepo {
  SettingsPreferencesModel loadPreferences();
  Stream<SettingsPreferencesModel> get preferencesChanges;
  Future<Either<Failure, Unit>> updateUserName(String name);
  Future<Either<Failure, Unit>> changeLanguage(String languageCode);
  Future<Either<Failure, Unit>> setNotificationsEnabled(bool enabled);
  Future<Either<Failure, bool>> requestScreenTimePermission();

  /// Deletes all local data (plan, history, flags) — "start fresh".
  Future<Either<Failure, Unit>> resetApp();
}

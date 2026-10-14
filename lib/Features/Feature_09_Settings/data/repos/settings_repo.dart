import 'dart:ui';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../data_sources/store_review_platform_data_source.dart';
import '../models/settings_preferences_model.dart';

abstract class SettingsRepo {
  SettingsPreferencesModel loadPreferences();
  Stream<SettingsPreferencesModel> get preferencesChanges;
  Future<Either<Failure, Unit>> updateUserName(String name);
  Future<Either<Failure, Unit>> changeLanguage(String languageCode);
  Future<Either<Failure, Unit>> setNotificationsEnabled(bool enabled);
  Future<Either<Failure, bool>> requestScreenTimePermission();

  /// "Rate Sinkly": native Apple / Google rating sheet (store page fallback).
  Future<Either<Failure, StoreReviewOutcome>> requestAppReview();

  /// "Share with a friend": system share sheet. `Right(true)` = shared.
  Future<Either<Failure, bool>> shareInvite({required String message, required String subject, Rect? origin});
}

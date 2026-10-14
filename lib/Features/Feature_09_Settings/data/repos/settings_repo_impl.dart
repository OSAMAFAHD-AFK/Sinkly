import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../Feature_02_Onboarding/data/data_sources/device_permissions_data_source.dart';
import '../data_sources/app_share_platform_data_source.dart';
import '../data_sources/settings_local_data_source.dart';
import '../data_sources/store_review_platform_data_source.dart';
import '../models/settings_preferences_model.dart';
import 'settings_repo.dart';

class SettingsRepoImpl implements SettingsRepo {
  SettingsRepoImpl({
    required SettingsLocalDataSource localDataSource,
    required DevicePermissionsDataSource permissionsDataSource,
    required StoreReviewPlatformDataSource storeReviewDataSource,
    required AppSharePlatformDataSource shareDataSource,
    required this._localeController,
  }) : _local = localDataSource,
       _permissions = permissionsDataSource,
       _storeReview = storeReviewDataSource,
       _share = shareDataSource;

  final SettingsLocalDataSource _local;
  final DevicePermissionsDataSource _permissions;
  final StoreReviewPlatformDataSource _storeReview;
  final AppSharePlatformDataSource _share;
  final LocaleController _localeController;

  SettingsPreferencesModel _fromPlan() =>
      SettingsPreferencesModel.fromPlan(_local.readPlan(), languageCode: _localeController.locale.languageCode);

  @override
  SettingsPreferencesModel loadPreferences() => _fromPlan();

  @override
  Stream<SettingsPreferencesModel> get preferencesChanges => _local.planChanges.map((_) => _fromPlan());

  Future<Either<Failure, Unit>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return right(unit);
    } catch (error) {
      return left(CacheFailure('error_generic', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value(left(const ValidationFailure('settings_name_error_empty')));
    return _guard(() => _local.savePlan(_local.readPlan().copyWith(userName: trimmed)));
  }

  @override
  Future<Either<Failure, Unit>> changeLanguage(String languageCode) => _guard(() async {
    await _localeController.changeLanguage(languageCode);
    await _local.savePlan(_local.readPlan().copyWith(languageCode: languageCode));
  });

  @override
  Future<Either<Failure, Unit>> setNotificationsEnabled(bool enabled) => _guard(() async {
    if (enabled) await _permissions.requestNotificationPermission();
    await _local.savePlan(_local.readPlan().copyWith(notificationsEnabled: enabled));
  });

  @override
  Future<Either<Failure, bool>> requestScreenTimePermission() async {
    try {
      final granted = await _permissions.requestScreenTimeAuthorization();
      await _local.savePlan(_local.readPlan().copyWith(screenTimePermissionGranted: granted));
      return right(granted);
    } catch (error) {
      return left(PermissionFailure('error_permission_screen_time', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, StoreReviewOutcome>> requestAppReview() async {
    try {
      return right(await _storeReview.requestReview());
    } catch (error) {
      return left(PlatformFailure('settings_rate_unavailable', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, bool>> shareInvite({required String message, required String subject, Rect? origin}) async {
    try {
      return right(await _share.shareText(text: message, subject: subject, origin: origin));
    } catch (error) {
      debugPrint('[Share] share sheet failed: $error');
      return left(PlatformFailure('settings_share_error', debugMessage: '$error'));
    }
  }
}

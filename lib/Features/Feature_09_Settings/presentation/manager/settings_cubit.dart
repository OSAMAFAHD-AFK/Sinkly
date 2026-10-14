import 'dart:async';
import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/data_sources/store_review_platform_data_source.dart';
import '../../data/models/settings_preferences_model.dart';
import '../../data/models/share_invite_outcome.dart';
import '../../data/repos/settings_repo.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(SettingsState(preferences: _repo.loadPreferences())) {
    _subscription = _repo.preferencesChanges.listen((preferences) {
      if (!isClosed) emit(state.copyWith(preferences: preferences));
    });
  }

  final SettingsRepo _repo;
  late final StreamSubscription<SettingsPreferencesModel> _subscription;

  void _handle(Either<Failure, Object?> result) =>
      result.fold((failure) => emit(state.copyWith(failureKey: failure.messageKey)), (_) {});

  Future<void> updateUserName(String name) async => _handle(await _repo.updateUserName(name));

  Future<void> changeLanguage(String code) async {
    _handle(await _repo.changeLanguage(code));
    emit(state.copyWith(preferences: _repo.loadPreferences()));
  }

  Future<void> setNotificationsEnabled(bool enabled) async => _handle(await _repo.setNotificationsEnabled(enabled));

  Future<void> requestScreenTimePermission() async {
    emit(state.copyWith(isRequestingPermission: true));
    final result = await _repo.requestScreenTimePermission();
    emit(state.copyWith(isRequestingPermission: false));
    _handle(result);
  }

  /// Returns how the request was handled (null on failure, already reported).
  Future<StoreReviewOutcome?> rateApp() async {
    final result = await _repo.requestAppReview();
    _handle(result);
    return result.fold((_) => null, (outcome) => outcome);
  }

  /// The share sheet itself reacts to a failure (it copies the message), so
  /// nothing is reported through [SettingsState.failureKey] here.
  Future<ShareInviteOutcome> shareInvite({required String message, required String subject, Rect? origin}) async {
    final result = await _repo.shareInvite(message: message, subject: subject, origin: origin);
    return result.fold(
      (_) => ShareInviteOutcome.failed,
      (shared) => shared ? ShareInviteOutcome.shared : ShareInviteOutcome.dismissed,
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

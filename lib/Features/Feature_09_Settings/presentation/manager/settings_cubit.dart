import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/settings_preferences_model.dart';
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

  Future<bool> resetApp() async => (await _repo.resetApp()).isRight();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

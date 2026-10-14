import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/app_constants.dart';
import '../../data/repos/sink_unlock_repo.dart';

part 'sink_unlock_state.dart';

/// intro → timed sprint (default 5 min, user-adjustable) → photo → verification → celebration (apps unlocked).
class SinkUnlockCubit extends Cubit<SinkUnlockState> {
  SinkUnlockCubit(this._repo)
    : super(
        SinkUnlockState(
          stage: SinkUnlockStage.intro,
          lockStatus: _repo.currentLockStatus(now: DateTime.now()),
          blockedApps: _repo.blockedApps(),
          remainingSeconds: _repo.sprintMinutes() * 60,
          sprintTotalSeconds: _repo.sprintMinutes() * 60,
          userName: _repo.userName(),
        ),
      );

  final SinkUnlockRepo _repo;
  Timer? _sprintTimer;

  void startSprint() {
    final startedAt = DateTime.now();
    emit(state.copyWith(stage: SinkUnlockStage.sprinting, sprintStartedAt: startedAt, clearFailure: true));
    _sprintTimer?.cancel();
    // Wall-clock based so the countdown stays correct after backgrounding.
    _sprintTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      // Read the total every tick so adjusting the timer mid-sprint applies at once.
      final total = state.sprintTotalSeconds;
      final remaining = (total - elapsed).clamp(0, total);
      emit(state.copyWith(remainingSeconds: remaining));
      if (remaining == 0) _sprintTimer?.cancel();
    });
  }

  /// Lets the user pick how long the sprint lasts — before starting, or
  /// while it runs (the elapsed time is kept; only the total changes).
  Future<void> setSprintMinutes(int minutes) async {
    final safe = minutes.clamp(AppConstants.minSprintMinutes, AppConstants.maxSprintMinutes);
    final total = safe * 60;
    if (total == state.sprintTotalSeconds) return;
    final startedAt = state.sprintStartedAt;
    final elapsed = startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds;
    emit(state.copyWith(sprintTotalSeconds: total, remainingSeconds: (total - elapsed).clamp(0, total)));
    await _repo.saveSprintMinutes(safe);
  }

  /// Opens the camera, then verifies the photo, then unlocks.
  /// Allowed any time — the timer is a guide, the photo is the proof.
  Future<void> captureAndVerifyPhoto() async {
    if (state.isCapturing) return;
    emit(state.copyWith(isCapturing: true, clearFailure: true));
    final captureResult = await _repo.captureSinkPhoto();
    final photoPath = captureResult.fold((failure) {
      emit(state.copyWith(isCapturing: false, failureKey: failure.messageKey));
      return null;
    }, (path) => path);
    if (photoPath == null) {
      if (state.isCapturing) emit(state.copyWith(isCapturing: false)); // cancelled
      return;
    }

    emit(state.copyWith(stage: SinkUnlockStage.verifying, photoPath: photoPath, isCapturing: false));
    final verification = await _repo.verifySinkPhoto(photoPath);
    await verification.fold(
      (failure) async => emit(
        state.copyWith(
          stage: state.sprintStartedAt == null ? SinkUnlockStage.intro : SinkUnlockStage.sprinting,
          failureKey: failure.messageKey,
        ),
      ),
      (_) => _completeSession(photoPath),
    );
  }

  Future<void> _completeSession(String photoPath) async {
    _sprintTimer?.cancel();
    final result = await _repo.completeSession(
      startedAt: state.sprintStartedAt ?? DateTime.now(),
      photoPath: photoPath,
      triggeringMeal: state.lockStatus.lockingMeal,
    );
    result.fold((failure) => emit(state.copyWith(stage: SinkUnlockStage.sprinting, failureKey: failure.messageKey)), (
      session,
    ) {
      final now = DateTime.now();
      emit(
        state.copyWith(
          stage: SinkUnlockStage.celebrating,
          completedSession: session,
          lockStatus: _repo.currentLockStatus(now: now),
          statsAfterUnlock: _repo.progressStats(now: now),
        ),
      );
    });
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() {
    _sprintTimer?.cancel();
    return super.close();
  }
}

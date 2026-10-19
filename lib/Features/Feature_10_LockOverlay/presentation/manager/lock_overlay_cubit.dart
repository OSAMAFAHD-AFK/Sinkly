import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/lock_overlay_snapshot_model.dart';
import '../../data/repos/lock_overlay_repo.dart';

part 'lock_overlay_state.dart';

/// Lock overlay shown when a locked app is opened: holds the snapshot and
/// which act of the heroine's pep-talk is playing.
class LockOverlayCubit extends Cubit<LockOverlayState> {
  LockOverlayCubit(this._repo, {String? attemptedAppId, String? attemptedAppName})
    : super(
        LockOverlayState(
          snapshot: _repo.loadSnapshot(
            now: DateTime.now(),
            attemptedAppId: attemptedAppId,
            attemptedAppName: attemptedAppName,
          ),
        ),
      );

  final LockOverlayRepo _repo;

  /// Next act of the pep-talk (auto every few seconds, or on tapping her).
  void nextAct() => emit(state.copyWith(actIndex: state.actIndex + 1));

  /// Back press: the home screen, never back into the locked app.
  Future<void> leaveToHomeScreen() => _repo.leaveToHomeScreen();
}

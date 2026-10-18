import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../Feature_06_SinkUnlock/data/data_sources/app_blocking_platform_data_source.dart';
import '../../data/models/app_start_destination_model.dart';
import '../../data/repos/splash_repo.dart';

/// Session gate behind the splash animation: emits where to go once the
/// brand animation has played (`null` while it is still playing).
class SplashCubit extends Cubit<AppStartDestination?> {
  SplashCubit(this._repo) : super(null);

  final SplashRepo _repo;

  /// Set when Sinkly was opened from a locked app's lock screen: the view
  /// opens the lock overlay right after Home.
  LockOverlayRequest? pendingLockOverlay;

  /// Plays the brand animation, then routes. Opened from a lock screen, it
  /// skips the animation: the user is in the middle of something.
  Future<void> start(Duration brandAnimation) async {
    final destination = _repo.resolveStartDestination();
    if (destination == AppStartDestination.home) pendingLockOverlay = await _repo.consumePendingLockOverlay();
    if (pendingLockOverlay == null) await Future<void>.delayed(brandAnimation);
    if (!isClosed) emit(destination);
  }
}

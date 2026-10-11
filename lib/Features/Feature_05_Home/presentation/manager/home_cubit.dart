import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/home_dashboard_model.dart';
import '../../data/repos/home_repo.dart';

part 'home_state.dart';

/// Keeps the dashboard live: reacts to plan/session changes, re-evaluates the
/// lock every 30 s (meal times passing) and when the app returns to foreground.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo) : super(_build(_repo)) {
    _dataSubscription = _repo.dataChanges.listen((_) => refresh());
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    _lifecycleListener = AppLifecycleListener(onResume: refresh);
  }

  final HomeRepo _repo;
  late final StreamSubscription<void> _dataSubscription;
  late final Timer _ticker;
  late final AppLifecycleListener _lifecycleListener;

  static DateTime _minuteNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  static HomeState _build(HomeRepo repo) {
    final now = DateTime.now();
    return HomeState(
      dashboard: repo.buildDashboard(now: now),
      now: _minuteNow(),
    );
  }

  /// Equatable state ⇒ widgets rebuild only when something actually changed.
  void refresh() {
    if (!isClosed) emit(_build(_repo));
  }

  @override
  Future<void> close() async {
    await _dataSubscription.cancel();
    _ticker.cancel();
    _lifecycleListener.dispose();
    return super.close();
  }
}

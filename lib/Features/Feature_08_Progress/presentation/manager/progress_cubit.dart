import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/progress_overview_model.dart';
import '../../data/repos/progress_repo.dart';

part 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._repo) : super(_build(_repo)) {
    _subscription = _repo.dataChanges.listen((_) => refresh());
  }

  final ProgressRepo _repo;
  late final StreamSubscription<void> _subscription;

  static ProgressState _build(ProgressRepo repo) {
    final now = DateTime.now();
    return ProgressState(
      overview: repo.buildOverview(now: now),
      today: DateTime(now.year, now.month, now.day),
    );
  }

  void refresh() {
    if (!isClosed) emit(_build(_repo));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

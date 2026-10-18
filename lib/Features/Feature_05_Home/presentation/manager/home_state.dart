part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({required this.dashboard, required this.now, this.protection = BlockingStatusModel.unknown});

  final HomeDashboardModel dashboard;

  /// Native blocker health (drives the "protection is off" banner).
  final BlockingStatusModel protection;

  /// Clock snapshot (minute precision) used for countdown labels.
  final DateTime now;

  @override
  List<Object?> get props => [dashboard, now, protection];
}

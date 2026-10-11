part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({required this.dashboard, required this.now});

  final HomeDashboardModel dashboard;

  /// Clock snapshot (minute precision) used for countdown labels.
  final DateTime now;

  @override
  List<Object?> get props => [dashboard, now];
}

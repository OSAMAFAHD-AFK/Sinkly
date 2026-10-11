part of 'progress_cubit.dart';

class ProgressState extends Equatable {
  const ProgressState({required this.overview, required this.today});

  final ProgressOverviewModel overview;
  final DateTime today;

  @override
  List<Object?> get props => [overview, today];
}

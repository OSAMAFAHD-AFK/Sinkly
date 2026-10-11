import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

enum TodayMealStatus { cleaned, locked, upcoming }

/// One meal on today's timeline with its lock outcome.
class TodayMealStatusModel extends Equatable {
  const TodayMealStatusModel({required this.meal, required this.at, required this.status});

  final MealType meal;
  final DateTime at;
  final TodayMealStatus status;

  @override
  List<Object?> get props => [meal, at, status];
}

/// Everything the Home tab renders, computed in one place.
class HomeDashboardModel extends Equatable {
  const HomeDashboardModel({
    required this.plan,
    required this.lockStatus,
    required this.stats,
    required this.todayMeals,
  });

  final UserPlanModel plan;
  final LockStatusModel lockStatus;
  final SinkProgressStatsModel stats;
  final List<TodayMealStatusModel> todayMeals;

  @override
  List<Object?> get props => [plan, lockStatus, stats, todayMeals];
}

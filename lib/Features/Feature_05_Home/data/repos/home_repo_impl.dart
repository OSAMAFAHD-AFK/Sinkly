import 'dart:async';

import '../../../../core/models/shared_core_models.dart';
import '../data_sources/home_local_data_source.dart';
import '../models/home_dashboard_model.dart';
import 'home_repo.dart';

class HomeRepoImpl implements HomeRepo {
  HomeRepoImpl(this._local);

  final HomeLocalDataSource _local;

  @override
  Stream<void> get dataChanges {
    late final StreamController<void> controller;
    StreamSubscription<UserPlanModel>? planSubscription;
    StreamSubscription<List<SinkCleaningSessionModel>>? sessionsSubscription;
    controller = StreamController<void>(
      onListen: () {
        planSubscription = _local.planChanges.listen((_) => controller.add(null));
        sessionsSubscription = _local.sessionsChanges.listen((_) => controller.add(null));
      },
      onCancel: () async {
        await planSubscription?.cancel();
        await sessionsSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  HomeDashboardModel buildDashboard({required DateTime now}) {
    final plan = _local.readPlan();
    final sessions = _local.readSessions();
    return HomeDashboardModel(
      plan: plan,
      lockStatus: LockStatusModel.evaluate(plan: plan, sessions: sessions, now: now),
      stats: SinkProgressStatsModel.fromSessions(sessions, now: now),
      todayMeals: _todayMeals(plan, sessions, now),
    );
  }

  List<TodayMealStatusModel> _todayMeals(UserPlanModel plan, List<SinkCleaningSessionModel> sessions, DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final dayPlan = plan.schedule.dayPlan(now.weekday);
    if (!dayPlan.isActive) return const [];

    final meals = [...dayPlan.meals]..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return [
      for (var i = 0; i < meals.length; i++)
        () {
          final at = startOfToday.add(Duration(minutes: meals[i].minutesOfDay));
          final nextAt = i + 1 < meals.length ? startOfToday.add(Duration(minutes: meals[i + 1].minutesOfDay)) : null;
          final TodayMealStatus status;
          if (at.isAfter(now)) {
            status = TodayMealStatus.upcoming;
          } else {
            // Cleaned if a session finished after this meal (and before the next one ended).
            final cleaned = sessions.any(
              (session) =>
                  !session.completedAt.isBefore(at) &&
                  (nextAt == null || session.completedAt.isBefore(nextAt) || nextAt.isAfter(now)),
            );
            status = cleaned ? TodayMealStatus.cleaned : TodayMealStatus.locked;
          }
          return TodayMealStatusModel(meal: meals[i].type, at: at, status: status);
        }(),
    ];
  }
}

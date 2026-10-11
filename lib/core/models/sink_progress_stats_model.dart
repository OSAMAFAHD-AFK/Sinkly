import 'package:equatable/equatable.dart';

import '../utils/app_constants.dart';
import 'sink_cleaning_session_model.dart';

/// Aggregated progress numbers derived from cleaning sessions.
/// Pure & deterministic (pass `now`) so it is trivial to unit-test.
class SinkProgressStatsModel extends Equatable {
  const SinkProgressStatsModel({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.totalCleans,
    required this.cleansThisWeek,
    required this.minutesReclaimed,
    required this.averageCleaningDuration,
    required this.cleansPerDayLast7,
  });

  final int currentStreakDays;
  final int bestStreakDays;
  final int totalCleans;
  final int cleansThisWeek;
  final int minutesReclaimed;
  final Duration averageCleaningDuration;

  /// Oldest → today, 7 entries.
  final List<int> cleansPerDayLast7;

  static const SinkProgressStatsModel empty = SinkProgressStatsModel(
    currentStreakDays: 0,
    bestStreakDays: 0,
    totalCleans: 0,
    cleansThisWeek: 0,
    minutesReclaimed: 0,
    averageCleaningDuration: Duration.zero,
    cleansPerDayLast7: [0, 0, 0, 0, 0, 0, 0],
  );

  factory SinkProgressStatsModel.fromSessions(List<SinkCleaningSessionModel> sessions, {required DateTime now}) {
    if (sessions.isEmpty) return empty;

    DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);
    final today = dayOf(now);
    final cleanDays = sessions.map((session) => dayOf(session.completedAt)).toSet();

    // Current streak: consecutive days ending today (or yesterday, so the
    // streak isn't "lost" before today's first meal).
    var cursor = cleanDays.contains(today) ? today : DateTime(today.year, today.month, today.day - 1);
    var current = 0;
    while (cleanDays.contains(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    // Best streak across history.
    final sortedDays = cleanDays.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in sortedDays) {
      run = previous != null && DateTime(previous.year, previous.month, previous.day + 1) == day ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }

    final perDay = List<int>.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return sessions.where((session) => dayOf(session.completedAt) == day).length;
    });

    final totalSeconds = sessions.fold<int>(0, (sum, session) => sum + session.cleaningDuration.inSeconds);

    return SinkProgressStatsModel(
      currentStreakDays: current,
      bestStreakDays: best,
      totalCleans: sessions.length,
      cleansThisWeek: perDay.fold(0, (sum, count) => sum + count),
      minutesReclaimed: sessions.length * AppConstants.minutesReclaimedPerClean,
      averageCleaningDuration: Duration(seconds: totalSeconds ~/ sessions.length),
      cleansPerDayLast7: List.unmodifiable(perDay),
    );
  }

  @override
  List<Object?> get props => [
    currentStreakDays,
    bestStreakDays,
    totalCleans,
    cleansThisWeek,
    minutesReclaimed,
    averageCleaningDuration,
    cleansPerDayLast7,
  ];
}

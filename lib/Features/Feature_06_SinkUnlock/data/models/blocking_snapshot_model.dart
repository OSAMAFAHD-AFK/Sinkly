import 'package:equatable/equatable.dart';

import '../../../../core/models/shared_core_models.dart';

/// Everything the native blocker needs, sent whenever something changes
/// (plan saved, sink cleaned, test lock, subscription, language).
///
/// The native side stores it and decides on its own — even while Sinkly is
/// closed — with the same rule as [LockStatusModel.evaluate].
/// Instants travel as UTC epoch milliseconds; meal times as the phone's
/// local wall clock (weekday + minutes after midnight).
class BlockingSnapshotModel extends Equatable {
  const BlockingSnapshotModel({
    required this.enabled,
    required this.days,
    required this.mealTypes,
    required this.blockedPackages,
    required this.blockedCategories,
    required this.strings,
    required this.languageCode,
    this.activeSince,
    this.lastCleanAt,
    this.manualLockAt,
    this.remindersEnabled = true,
  });

  /// Onboarding finished and the subscription is active. `false` = never
  /// lock (the plan is kept for when the user subscribes again).
  final bool enabled;
  final DateTime? activeSince;
  final DateTime? lastCleanAt;
  final DateTime? manualLockAt;

  /// Settings "Reminders" switch. Off = the blocker's always-on Android
  /// notification goes minimized (no status-bar icon, no "next lock" line).
  final bool remindersEnabled;

  /// ISO weekday (1 = Monday … 7 = Sunday) → meal end times in minutes after
  /// midnight. Only active days are present.
  final Map<int, List<int>> days;

  /// Same shape as [days]: the meal kind of each time ("breakfast", "lunch",
  /// "dinner"), so the native lock screen can say "Dinner's done".
  final Map<int, List<String>> mealTypes;

  /// Android: package names locked explicitly.
  final List<String> blockedPackages;

  /// Android: whole categories (also covers apps installed later).
  final List<String> blockedCategories;

  /// Localized copy for the native lock screen, notification and iOS shield.
  final Map<String, String> strings;
  final String languageCode;

  /// Some apps ship under more than one package name.
  static const Map<String, List<String>> _packageAliases = {
    'com.zhiliaoapp.musically': ['com.ss.android.ugc.trill'],
    'com.facebook.katana': ['com.facebook.lite'],
  };

  factory BlockingSnapshotModel.from({
    required UserPlanModel plan,
    required List<SinkCleaningSessionModel> sessions,
    required bool enabled,
    required Map<String, String> strings,
    required String languageCode,
  }) {
    final packages = <String>{};
    for (final id in plan.blockedAppIds) {
      // Catalog ids ("tiktok") map to their package; other ids ARE packages.
      final package = BlockableAppModel.byId(id)?.platformIdentifier ?? id;
      packages
        ..add(package)
        ..addAll(_packageAliases[package] ?? const []);
    }
    final lastCleanAt = sessions.isEmpty
        ? null
        : sessions.map((session) => session.completedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    return BlockingSnapshotModel(
      enabled: enabled,
      activeSince: enabled ? plan.lockingActiveSince : null,
      lastCleanAt: lastCleanAt,
      manualLockAt: plan.manualLockTriggeredAt,
      remindersEnabled: plan.notificationsEnabled,
      days: {
        for (final weekday in plan.schedule.activeWeekdays)
          weekday: [for (final meal in _sortedMeals(plan, weekday)) meal.minutesOfDay],
      },
      mealTypes: {
        for (final weekday in plan.schedule.activeWeekdays)
          weekday: [for (final meal in _sortedMeals(plan, weekday)) meal.type.name],
      },
      blockedPackages: (packages.toList()..sort()),
      blockedCategories: ([...plan.blockedCategoryIds]..sort()),
      strings: strings,
      languageCode: languageCode,
    );
  }

  static List<MealSlotModel> _sortedMeals(UserPlanModel plan, int weekday) =>
      [...plan.schedule.dayPlan(weekday).meals]..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

  /// Wire format of channel `sinkly/app_blocking` (`apply`).
  Map<String, Object?> toChannel() => {
    'enabled': enabled,
    'activeSinceMs': activeSince?.millisecondsSinceEpoch,
    'lastCleanAtMs': lastCleanAt?.millisecondsSinceEpoch,
    'manualLockAtMs': manualLockAt?.millisecondsSinceEpoch,
    'remindersEnabled': remindersEnabled,
    'days': {for (final entry in days.entries) '${entry.key}': entry.value},
    'mealTypes': {for (final entry in mealTypes.entries) '${entry.key}': entry.value},
    'blockedPackages': blockedPackages,
    'blockedCategories': blockedCategories,
    'strings': strings,
    'languageCode': languageCode,
  };

  @override
  List<Object?> get props => [
    enabled,
    activeSince,
    lastCleanAt,
    manualLockAt,
    remindersEnabled,
    days.entries.map((entry) => '${entry.key}:${entry.value.join(',')}').join('|'),
    mealTypes.entries.map((entry) => '${entry.key}:${entry.value.join(',')}').join('|'),
    blockedPackages,
    blockedCategories,
    strings.entries.map((entry) => '${entry.key}=${entry.value}').join('|'),
    languageCode,
  ];
}

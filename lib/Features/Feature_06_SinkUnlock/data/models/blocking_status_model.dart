import 'package:equatable/equatable.dart';

/// What still keeps the native blocker from working.
enum BlockingRequirement {
  /// Android "Usage access" (which app is in front).
  usageAccess('usageAccess'),

  /// Android "Display over other apps" (draw the lock screen).
  displayOverApps('displayOverApps'),

  /// iOS Screen Time (Family Controls) authorization.
  familyControls('familyControls'),

  /// Android battery optimization may stop the blocker (advice, not fatal).
  batteryOptimization('batteryOptimization');

  const BlockingRequirement(this.id);

  final String id;

  static BlockingRequirement? byId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// The native blocker's own view of things (channel `sinkly/app_blocking`).
class BlockingStatusModel extends Equatable {
  const BlockingStatusModel({
    required this.enabled,
    required this.isLocked,
    required this.missing,
    this.lockedSince,
    this.nextLockAt,
  });

  /// Nothing is reported yet (desktop, tests, before the first sync).
  static const BlockingStatusModel unknown = BlockingStatusModel(enabled: false, isLocked: false, missing: {});

  final bool enabled;
  final bool isLocked;
  final DateTime? lockedSince;
  final DateTime? nextLockAt;
  final Set<BlockingRequirement> missing;

  /// Locking is on but a required access was removed: apps can't be locked.
  bool get isProtectionBroken =>
      enabled &&
      missing.any(
        (requirement) => requirement != BlockingRequirement.batteryOptimization,
      );

  factory BlockingStatusModel.fromChannel(Map<Object?, Object?> map) {
    DateTime? instant(Object? value) => value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    return BlockingStatusModel(
      enabled: map['enabled'] == true,
      isLocked: map['isLocked'] == true,
      lockedSince: instant(map['lockedSinceMs']),
      nextLockAt: instant(map['nextLockAtMs']),
      missing: {for (final id in (map['missing'] as List?) ?? const []) ?BlockingRequirement.byId('$id')},
    );
  }

  @override
  List<Object?> get props => [enabled, isLocked, lockedSince, nextLockAt, missing];
}

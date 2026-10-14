part of 'lock_overlay_cubit.dart';

class LockOverlayState extends Equatable {
  const LockOverlayState({required this.snapshot, this.actIndex = 0});

  final LockOverlaySnapshotModel snapshot;

  /// Ever-increasing; the view wraps it around its list of acts.
  final int actIndex;

  LockOverlayState copyWith({int? actIndex}) =>
      LockOverlayState(snapshot: snapshot, actIndex: actIndex ?? this.actIndex);

  @override
  List<Object?> get props => [snapshot, actIndex];
}

import 'package:equatable/equatable.dart';

/// One local notification, ready to schedule.
class ReminderModel extends Equatable {
  const ReminderModel({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
  });

  /// Fixed id ranges per kind, so a kind can be replaced without touching the other.
  static const int trialEndId = 1000;
  static const int firstLockId = 2000;
  static const int maxLockReminders = 30;

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// Android notification channel (users can mute each kind in Settings).
  final String channelId;
  final String channelName;

  @override
  List<Object?> get props => [id, at, title, body, channelId, channelName];
}

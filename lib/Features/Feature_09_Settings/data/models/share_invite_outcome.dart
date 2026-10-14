/// What happened to a "Share with a friend" request.
enum ShareInviteOutcome {
  /// The user picked an app in the system share sheet.
  shared,

  /// The user closed the share sheet without sending.
  dismissed,

  /// Sharing could not be opened at all (the sheet then copies the message
  /// instead, so the user is never left at a dead end).
  failed,
}

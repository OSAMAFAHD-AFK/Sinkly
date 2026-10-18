import Foundation

/// What the blocker needs, sent by Flutter (`AppBlockingRepo`) over channel
/// `sinkly/app_blocking` and kept in the App Group so the extensions read it
/// while Sinkly is closed. Instants are UTC epoch milliseconds; meal times are
/// the phone's wall clock: ISO weekday ("1" = Monday … "7" = Sunday) → minutes
/// after midnight.
struct SinklySnapshot: Codable, Equatable {
  var enabled: Bool
  var activeSinceMs: Int64?
  var lastCleanAtMs: Int64?
  var manualLockAtMs: Int64?
  var days: [String: [Int]]
  var strings: [String: String]
  var languageCode: String
  /// Same shape as [days]: "breakfast" / "lunch" / "dinner" for each time.
  var mealTypes: [String: [String]]?

  static let disabled = SinklySnapshot(
    enabled: false, activeSinceMs: nil, lastCleanAtMs: nil, manualLockAtMs: nil,
    days: [:], strings: [:], languageCode: "en")

  /// From the Flutter channel map (`BlockingSnapshotModel.toChannel`).
  init(channel map: [String: Any]) {
    func ms(_ key: String) -> Int64? { (map[key] as? NSNumber)?.int64Value }
    var days: [String: [Int]] = [:]
    for (key, value) in (map["days"] as? [String: Any]) ?? [:] {
      days[key] = ((value as? [Any]) ?? []).compactMap { ($0 as? NSNumber)?.intValue }
    }
    var mealTypes: [String: [String]] = [:]
    for (key, value) in (map["mealTypes"] as? [String: Any]) ?? [:] {
      mealTypes[key] = ((value as? [Any]) ?? []).compactMap { $0 as? String }
    }
    self.init(
      enabled: (map["enabled"] as? Bool) ?? false,
      activeSinceMs: ms("activeSinceMs"),
      lastCleanAtMs: ms("lastCleanAtMs"),
      manualLockAtMs: ms("manualLockAtMs"),
      days: days,
      strings: (map["strings"] as? [String: String]) ?? [:],
      languageCode: (map["languageCode"] as? String) ?? "en",
      mealTypes: mealTypes)
  }

  init(
    enabled: Bool, activeSinceMs: Int64?, lastCleanAtMs: Int64?, manualLockAtMs: Int64?,
    days: [String: [Int]], strings: [String: String], languageCode: String,
    mealTypes: [String: [String]]? = nil
  ) {
    self.enabled = enabled
    self.activeSinceMs = activeSinceMs
    self.lastCleanAtMs = lastCleanAtMs
    self.manualLockAtMs = manualLockAtMs
    self.days = days
    self.strings = strings
    self.languageCode = languageCode
    self.mealTypes = mealTypes
  }

  func text(_ key: String, _ fallback: String) -> String {
    if let value = strings[key], !value.isEmpty { return value }
    return fallback
  }

  var dayMap: [Int: [Int]] {
    var map: [Int: [Int]] = [:]
    for (key, minutes) in days { if let day = Int(key) { map[day] = minutes } }
    return map
  }

  var activeSince: Date? { activeSinceMs.map(Date.init(epochMilliseconds:)) }
  var lastCleanAt: Date? { lastCleanAtMs.map(Date.init(epochMilliseconds:)) }
  var manualLockAt: Date? { manualLockAtMs.map(Date.init(epochMilliseconds:)) }
}

struct SinklyLockState: Equatable {
  let locked: Bool
  let lockedSince: Date?
  let nextLockAt: Date?
}

/// THE lock rule — identical to Dart's `LockStatusModel.evaluate` and Kotlin's
/// `LockEngine`, checked against the same cases (test/fixtures/lock_engine_vectors.json):
///  • a lock starts when a planned meal ends (or "Test the lock now"),
///  • it lasts until a clean-sink photo — no expiry,
///  • only meals that end after locking became active count,
///  • meal times are the phone's wall clock in its current time zone, built
///    from clock fields, so 18:00 stays 18:00 on daylight-saving days.
enum SinklyLockEngine {
  /// The plan repeats weekly: the latest past meal is within 7 days.
  static let lookBackDays = 8

  static func evaluate(_ snapshot: SinklySnapshot, now: Date, calendar: Calendar = .current) -> SinklyLockState {
    let days = snapshot.dayMap
    let from = calendar.date(byAdding: .day, value: -lookBackDays, to: now) ?? now
    var latest = triggers(days: days, from: from, to: now, calendar: calendar).last

    if let manual = snapshot.manualLockAt, manual <= now {
      if latest == nil || manual > latest! { latest = manual }
    }

    let activeSince = snapshot.enabled ? snapshot.activeSince : nil
    let anchor: Date? = activeSince.map { active in
      if let clean = snapshot.lastCleanAt, clean > active { return clean }
      return active
    }

    var locked = false
    if let anchor = anchor, let latest = latest { locked = latest > anchor }

    let until = calendar.date(byAdding: .day, value: lookBackDays, to: now) ?? now
    let next = triggers(days: days, from: now.addingTimeInterval(1), to: until, calendar: calendar).first
    return SinklyLockState(locked: locked, lockedSince: locked ? latest : nil, nextLockAt: next)
  }

  /// Which meal started the lock at [lockedSince]: "breakfast" / "lunch" /
  /// "dinner", or nil for "Test the lock now" (or an unknown time).
  static func mealOf(_ snapshot: SinklySnapshot, lockedSince: Date?, calendar: Calendar = .current) -> String? {
    guard let lockedSince = lockedSince else { return nil }
    if let manual = snapshot.manualLockAtMs, manual == lockedSince.epochMilliseconds { return nil }
    let day = isoWeekday(calendar.component(.weekday, from: lockedSince))
    let minutes = calendar.component(.hour, from: lockedSince) * 60 + calendar.component(.minute, from: lockedSince)
    guard let index = snapshot.dayMap[day]?.firstIndex(of: minutes),
      let types = snapshot.mealTypes?[String(day)], index < types.count
    else { return nil }
    return types[index]
  }

  /// Every meal end inside [from, to], oldest first.
  static func triggers(days: [Int: [Int]], from: Date, to: Date, calendar: Calendar) -> [Date] {
    guard !days.isEmpty, from <= to else { return [] }
    var result: [Date] = []
    var day = calendar.startOfDay(for: from)
    let lastDay = calendar.startOfDay(for: to)
    while day <= lastDay {
      let iso = isoWeekday(calendar.component(.weekday, from: day))
      for minutes in days[iso] ?? [] {
        // A skipped time (spring forward) moves past the gap, keeping the minutes;
        // a repeated time (fall back) uses its first occurrence — like Kotlin.
        if let at = calendar.date(
          bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day,
          matchingPolicy: .nextTimePreservingSmallerComponents,
          repeatedTimePolicy: .first, direction: .forward),
          at >= from, at <= to
        {
          result.append(at)
        }
      }
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = calendar.startOfDay(for: next)
    }
    return result.sorted()
  }

  /// Apple: 1 = Sunday … 7 = Saturday → ISO: 1 = Monday … 7 = Sunday.
  static func isoWeekday(_ appleWeekday: Int) -> Int { appleWeekday == 1 ? 7 : appleWeekday - 1 }
}

extension Date {
  init(epochMilliseconds ms: Int64) { self.init(timeIntervalSince1970: TimeInterval(ms) / 1000) }
  var epochMilliseconds: Int64 { Int64((timeIntervalSince1970 * 1000).rounded()) }
}

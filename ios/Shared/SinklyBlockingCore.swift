import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Shared by the app (Runner) and the extensions. Add this file and
/// SinklyLockEngine.swift to: Runner, SinklyMonitorExtension,
/// SinklyShieldConfiguration and SinklyShieldAction (see ios/BLOCKING_SETUP.md).
enum SinklyShared {
  /// Must match the App Group capability of every target.
  static let appGroup = "group.com.sinkly.app"
}

/// The blocker's memory, in the App Group: readable by the extensions while
/// Sinkly is closed.
final class SinklyStore {
  static let shared = SinklyStore()

  let defaults: UserDefaults

  private enum Key {
    static let snapshot = "sinkly.blocking.snapshot"
    static let selection = "sinkly.familyActivitySelection"
    static let pendingId = "sinkly.blocking.pendingAppId"
    static let pendingName = "sinkly.blocking.pendingAppName"
  }

  private init() {
    defaults = UserDefaults(suiteName: SinklyShared.appGroup) ?? .standard
  }

  var snapshot: SinklySnapshot {
    get {
      guard let data = defaults.data(forKey: Key.snapshot),
        let saved = try? JSONDecoder().decode(SinklySnapshot.self, from: data)
      else { return .disabled }
      return saved
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: Key.snapshot) }
    }
  }

  /// The apps / categories picked in Apple's FamilyActivityPicker (opaque tokens).
  @available(iOS 16.0, *)
  var selection: FamilyActivitySelection {
    get {
      if let data = defaults.data(forKey: Key.selection),
        let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
      {
        return saved
      }
      // First launch after the App Group move: bring the old pick over.
      if let data = UserDefaults.standard.data(forKey: Key.selection),
        let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
      {
        defaults.set(data, forKey: Key.selection)
        return saved
      }
      return FamilyActivitySelection()
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: Key.selection) }
    }
  }

  /// Set by the shield's button: Sinkly opens straight on its lock screen.
  func setPendingLaunch(appId: String, appName: String) {
    defaults.set(appId, forKey: Key.pendingId)
    defaults.set(appName, forKey: Key.pendingName)
  }

  func consumePendingLaunch() -> (appId: String, appName: String)? {
    guard let id = defaults.string(forKey: Key.pendingId) else { return nil }
    let name = defaults.string(forKey: Key.pendingName) ?? ""
    defaults.removeObject(forKey: Key.pendingId)
    defaults.removeObject(forKey: Key.pendingName)
    return (id, name)
  }
}

/// Applies the lock rule to the system: shields the chosen apps while locked,
/// clears them otherwise, and keeps the meal-time schedules registered so the
/// DeviceActivityMonitor extension wakes up at the next lock even when Sinkly
/// is closed. Safe to call any time, from the app or an extension.
@available(iOS 16.0, *)
enum SinklyBlocking {
  private static let managedStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("sinkly"))
  private static let center = DeviceActivityCenter()
  private static let activityPrefix = "sinkly.lock."

  /// Apple limits how many activities one app may monitor; a rolling window of
  /// the next locks stays well below it and is renewed at every lock and
  /// every time Sinkly opens.
  private static let maxSchedules = 14

  /// DeviceActivity intervals must last at least 15 minutes.
  private static let intervalLength: TimeInterval = 30 * 60

  @discardableResult
  static func reconcile(now: Date = Date()) -> SinklyLockState {
    let snapshot = SinklyStore.shared.snapshot
    let state = SinklyLockEngine.evaluate(snapshot, now: now)
    if snapshot.enabled && state.locked {
      shieldSelection()
    } else {
      managedStore.clearAllSettings()
    }
    registerSchedules(snapshot, now: now)
    return state
  }

  /// The lock time encoded in an activity's name (`sinkly.lock.<epoch seconds>`).
  static func lockTime(of activity: DeviceActivityName) -> Date? {
    guard activity.rawValue.hasPrefix(activityPrefix),
      let seconds = TimeInterval(activity.rawValue.dropFirst(activityPrefix.count))
    else { return nil }
    return Date(timeIntervalSince1970: seconds)
  }

  private static func shieldSelection() {
    let selection = SinklyStore.shared.selection
    let apps = selection.applicationTokens
    let categories = selection.categoryTokens
    let domains = selection.webDomainTokens
    managedStore.shield.applications = apps.isEmpty ? nil : apps
    managedStore.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
    managedStore.shield.webDomains = domains.isEmpty ? nil : domains
    managedStore.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)
  }

  private static func registerSchedules(_ snapshot: SinklySnapshot, now: Date) {
    let ours = center.activities.filter { $0.rawValue.hasPrefix(activityPrefix) }
    if !ours.isEmpty { center.stopMonitoring(ours) }
    guard snapshot.enabled else { return }

    let calendar = Calendar.current
    let until = calendar.date(byAdding: .day, value: SinklyLockEngine.lookBackDays, to: now) ?? now
    let upcoming = SinklyLockEngine.triggers(
      days: snapshot.dayMap, from: now.addingTimeInterval(1), to: until, calendar: calendar
    ).prefix(maxSchedules)

    let fields: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    for start in upcoming {
      // Wall-clock components (no time zone): they follow the phone, like the plan.
      let schedule = DeviceActivitySchedule(
        intervalStart: calendar.dateComponents(fields, from: start),
        intervalEnd: calendar.dateComponents(fields, from: start.addingTimeInterval(intervalLength)),
        repeats: false)
      let name = DeviceActivityName("\(activityPrefix)\(Int(start.timeIntervalSince1970))")
      do {
        try center.startMonitoring(name, during: schedule)
      } catch {
        // Over Apple's limit or an invalid interval: the remaining locks are
        // picked up at the next reconcile (lock time or app launch).
        break
      }
    }
  }
}

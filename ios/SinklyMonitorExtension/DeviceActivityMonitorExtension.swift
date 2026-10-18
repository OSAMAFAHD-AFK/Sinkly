import DeviceActivity
import Foundation

/// Woken by iOS at every planned lock time, even when Sinkly is closed.
/// It applies the lock rule (shield the chosen apps) and renews the rolling
/// window of upcoming lock schedules. Keep it tiny: extensions get very
/// little memory.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    // Never evaluate a hair before the planned minute, even if iOS is early.
    let planned = SinklyBlocking.lockTime(of: activity)?.addingTimeInterval(1) ?? Date()
    SinklyBlocking.reconcile(now: max(Date(), planned))
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    // Nothing unlocks here — only a clean-sink photo does. Just refresh.
    SinklyBlocking.reconcile()
  }
}

import ManagedSettings
import UserNotifications

/// The shield's buttons. iOS doesn't let a shield open another app, so
/// "Clean my sink" leaves a request in the App Group and posts a notification:
/// tapping it opens Sinkly straight on its full lock screen (the Flutter
/// LockOverlay, via `consumeLaunchAction`). "Go to home screen" closes the
/// locked app.
final class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction, for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    respond(to: action, completionHandler)
  }

  override func handle(
    action: ShieldAction, for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    respond(to: action, completionHandler)
  }

  override func handle(
    action: ShieldAction, for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    respond(to: action, completionHandler)
  }

  private func respond(to action: ShieldAction, _ completionHandler: @escaping (ShieldActionResponse) -> Void) {
    switch action {
    case .primaryButtonPressed:
      SinklyStore.shared.setPendingLaunch(appId: "", appName: "")
      postOpenSinklyNotification { completionHandler(.close) }
    case .secondaryButtonPressed:
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  private func postOpenSinklyNotification(then done: @escaping () -> Void) {
    let snapshot = SinklyStore.shared.snapshot
    let content = UNMutableNotificationContent()
    content.title = snapshot.text("notifyTitle", "Your sink sprint is ready 🧽")
    content.body = snapshot.text("notifyBody", "Tap to open Sinkly, clean up and unlock your apps.")
    content.sound = .default
    // Delivered right away; needs Sinkly's notification permission. Without it
    // the shield's text already tells the user to open Sinkly.
    let request = UNNotificationRequest(identifier: "sinkly.open-from-shield", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { _ in done() }
  }
}

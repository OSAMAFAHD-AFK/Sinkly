import FamilyControls
import Flutter
import SwiftUI
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Local reminders (flutter_local_notifications) also show while Sinkly is open,
    // and a tap on the shield's "open Sinkly" notification reaches the app.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SinklyScreenTimePlugin") {
      SinklyScreenTimePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SinklyBlockingPlugin") {
      SinklyBlockingPlugin.register(with: registrar)
    }
  }
}

// MARK: - App blocker bridge
//
/// Channel `sinkly/app_blocking` (same contract as Android's AppBlockingBridge.kt):
///  • apply(snapshot)       → stores it in the App Group, shields / clears and
///                            re-registers the meal-time schedules → status
///  • getStatus             → {enabled, isLocked, lockedSinceMs, nextLockAtMs, missing[]}
///  • consumeLaunchAction   → {appId, appName, action: overlay} left by the shield's
///                            button, or nil → Flutter opens its full lock screen
///  • leaveToHomeScreen / openBatterySettings → nothing to do on iOS
///  • (native → Dart) openLockOverlay {appId, appName, action: overlay}
/// The real work lives in ios/Shared (also compiled into the extensions).
final class SinklyBlockingPlugin: NSObject {
  private static var instance: SinklyBlockingPlugin?
  private let channel: FlutterMethodChannel
  private var hasBeenActive = false
  private var activeObserver: NSObjectProtocol?

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    activeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.didBecomeActive() }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sinkly/app_blocking", binaryMessenger: registrar.messenger())
    let plugin = SinklyBlockingPlugin(channel: channel)
    channel.setMethodCallHandler(plugin.handle)
    instance = plugin
  }

  private func didBecomeActive() {
    // Catch up on anything missed while Sinkly was closed, renew schedules.
    if #available(iOS 16.0, *) { SinklyBlocking.reconcile() }
    // On a cold start Flutter reads the shield request itself after the splash.
    guard hasBeenActive else {
      hasBeenActive = true
      return
    }
    if let pending = SinklyStore.shared.consumePendingLaunch() {
      channel.invokeMethod(
        "openLockOverlay", arguments: ["appId": pending.appId, "appName": pending.appName, "action": "overlay"])
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "apply":
      guard let map = call.arguments as? [String: Any] else {
        return result(FlutterError(code: "BAD_SNAPSHOT", message: "apply expects a map", details: nil))
      }
      SinklyStore.shared.snapshot = SinklySnapshot(channel: map)
      if #available(iOS 16.0, *) { SinklyBlocking.reconcile() }
      result(status())
    case "getStatus":
      result(status())
    case "consumeLaunchAction":
      if let pending = SinklyStore.shared.consumePendingLaunch() {
        result(["appId": pending.appId, "appName": pending.appName, "action": "overlay"])
      } else {
        result(nil)
      }
    case "leaveToHomeScreen", "openBatterySettings":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func status() -> [String: Any] {
    let snapshot = SinklyStore.shared.snapshot
    let state = SinklyLockEngine.evaluate(snapshot, now: Date())
    var missing: [String] = []
    if snapshot.enabled {
      if #available(iOS 16.0, *) {
        if AuthorizationCenter.shared.authorizationStatus != .approved { missing.append("familyControls") }
      } else {
        missing.append("familyControls")
      }
    }
    func ms(_ date: Date?) -> Any {
      guard let date = date else { return NSNull() }
      return NSNumber(value: date.epochMilliseconds)
    }
    return [
      "enabled": snapshot.enabled,
      "isLocked": snapshot.enabled && state.locked,
      "lockedSinceMs": ms(state.lockedSince),
      "nextLockAtMs": ms(state.nextLockAt),
      "missing": missing,
    ]
  }
}

// MARK: - Screen Time bridge
//
// iOS never lets an app read the list of installed apps. Instead Apple's
// FamilyActivityPicker (Screen Time API) is embedded in Sinkly's screen; it
// renders the categories/apps itself and hands back opaque tokens, stored
// here and later used by ManagedSettings to shield the apps after meals.
//
// Requires the "Family Controls" capability (com.apple.developer.family-controls,
// see Runner.entitlements). Development works right away; App Store
// distribution needs Apple's approval: developer.apple.com/contact/request/family-controls-distribution

/// Channel `sinkly/screen_time` (same contract as Android's MainActivity.kt):
///  • getAuthorizationStatus → {familyControls: Bool}
///  • requestAuthorization → {familyControls: Bool} after Apple's alert
///  • getSelectionSummary → {apps, categories, webDomains}
///  • (native → Dart) selectionChanged {apps, categories, webDomains}
/// Platform view `sinkly/family_activity_picker` = the embedded picker.
final class SinklyScreenTimePlugin: NSObject {
  private static var instance: SinklyScreenTimePlugin?
  private let channel: FlutterMethodChannel

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sinkly/screen_time", binaryMessenger: registrar.messenger())
    let plugin = SinklyScreenTimePlugin(channel: channel)
    channel.setMethodCallHandler(plugin.handle)
    registrar.register(FamilyActivityPickerFactory(channel: channel), withId: "sinkly/family_activity_picker")
    instance = plugin
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAuthorizationStatus":
      result(Self.authorizationStatus())
    case "requestAuthorization":
      guard #available(iOS 16.0, *) else { return result(Self.authorizationStatus()) }
      // Apple's Screen Time alert, centred on screen over Sinkly's framed slot.
      Task {
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
          // Denied / cancelled / restricted: the status below says it all.
        }
        await MainActor.run { result(Self.authorizationStatus()) }
      }
    case "getSelectionSummary":
      if #available(iOS 16.0, *) {
        result(ScreenTimeSelectionStore.shared.summary)
      } else {
        result(["apps": 0, "categories": 0, "webDomains": 0])
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func authorizationStatus() -> [String: Bool] {
    guard #available(iOS 16.0, *) else { return ["familyControls": false] }
    return ["familyControls": AuthorizationCenter.shared.authorizationStatus == .approved]
  }
}

/// The user's picks (opaque tokens), kept in the App Group so the blocker
/// extensions can shield them while Sinkly is closed.
@available(iOS 16.0, *)
final class ScreenTimeSelectionStore {
  static let shared = ScreenTimeSelectionStore()

  var selection: FamilyActivitySelection {
    didSet {
      SinklyStore.shared.selection = selection
      // Picked apps changed (maybe while locked): shield the new set at once.
      SinklyBlocking.reconcile()
    }
  }

  private init() {
    selection = SinklyStore.shared.selection
  }

  var summary: [String: Int] {
    [
      "apps": selection.applicationTokens.count,
      "categories": selection.categoryTokens.count,
      "webDomains": selection.webDomainTokens.count,
    ]
  }
}

final class FamilyActivityPickerFactory: NSObject, FlutterPlatformViewFactory {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    FamilyActivityPickerPlatformView(frame: frame, channel: channel)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class FamilyActivityPickerPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, channel: FlutterMethodChannel) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    super.init()

    let content: UIViewController
    if #available(iOS 16.0, *) {
      content = UIHostingController(
        rootView: SinklyActivityPickerView { summary in
          channel.invokeMethod("selectionChanged", arguments: summary)
        }
      )
    } else {
      content = UIHostingController(
        rootView: Text("Choosing apps needs iOS 16 or later.")
          .multilineTextAlignment(.center)
          .padding()
      )
    }
    content.view.backgroundColor = .clear
    content.view.frame = container.bounds
    content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    container.addSubview(content.view)
    hostingController = content
  }

  func view() -> UIView {
    container
  }
}

/// Asks for Screen Time access the first time, then shows Apple's picker.
@available(iOS 16.0, *)
struct SinklyActivityPickerView: View {
  let onChange: ([String: Int]) -> Void

  @State private var selection = ScreenTimeSelectionStore.shared.selection
  @State private var status = AuthorizationCenter.shared.authorizationStatus

  var body: some View {
    Group {
      switch status {
      case .approved:
        FamilyActivityPicker(selection: $selection)
      case .denied:
        Text("Allow Screen Time access for Sinkly in Settings to choose the apps to lock.")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding()
      default:
        ProgressView()
      }
    }
    .task {
      guard status != .approved else { return }
      try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      status = AuthorizationCenter.shared.authorizationStatus
    }
    .onChange(of: selection) { newValue in
      ScreenTimeSelectionStore.shared.selection = newValue
      onChange(ScreenTimeSelectionStore.shared.summary)
    }
  }
}

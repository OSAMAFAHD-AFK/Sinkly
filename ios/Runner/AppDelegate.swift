import FamilyControls
import Flutter
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SinklyScreenTimePlugin") {
      SinklyScreenTimePlugin.register(with: registrar)
    }
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

/// Channel `sinkly/screen_time`:
///  • requestAuthorization → Bool
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
    case "requestAuthorization":
      guard #available(iOS 16.0, *) else { return result(false) }
      Task {
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          await MainActor.run { result(AuthorizationCenter.shared.authorizationStatus == .approved) }
        } catch {
          await MainActor.run { result(false) }
        }
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
}

/// The user's picks (opaque tokens), persisted across launches.
@available(iOS 16.0, *)
final class ScreenTimeSelectionStore {
  static let shared = ScreenTimeSelectionStore()
  private let storageKey = "sinkly.familyActivitySelection"

  var selection: FamilyActivitySelection {
    didSet { persist() }
  }

  private init() {
    if let data = UserDefaults.standard.data(forKey: storageKey),
       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
      selection = saved
    } else {
      selection = FamilyActivitySelection()
    }
  }

  var summary: [String: Int] {
    [
      "apps": selection.applicationTokens.count,
      "categories": selection.categoryTokens.count,
      "webDomains": selection.webDomainTokens.count,
    ]
  }

  private func persist() {
    if let data = try? JSONEncoder().encode(selection) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
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

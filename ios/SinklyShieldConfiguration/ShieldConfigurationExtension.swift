import ManagedSettings
import ManagedSettingsUI
import UIKit

/// What a locked app shows on iPhone: the same static lock card as Android
/// (blocking/LockCoverOverlay.kt) — warm peach backdrop, the heroine, the same
/// title / subtitle / buttons in the app's language and the sky "Clean my
/// sink" button. Apple draws this screen itself (only colours, an icon and
/// four texts can be chosen), so the layout is Apple's.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    make()
  }

  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
    make()
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    make()
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
    make()
  }

  private func make() -> ShieldConfiguration {
    let snapshot = SinklyStore.shared.snapshot
    return ShieldConfiguration(
      backgroundBlurStyle: .systemUltraThinMaterialLight,
      backgroundColor: Palette.peach,
      icon: UIImage(named: "lock_heroine"),
      title: ShieldConfiguration.Label(text: snapshot.text("lockTitle", "Your sink's turn!"), color: Palette.ink),
      subtitle: ShieldConfiguration.Label(
        text: snapshot.text(
          "lockSubtitle", "This app is taking a short break. One photo of a clean sink brings everything back."),
        color: Palette.inkSoft),
      primaryButtonLabel: ShieldConfiguration.Label(text: snapshot.text("lockCta", "Clean my sink"), color: Palette.onPrimary),
      primaryButtonBackgroundColor: Palette.primary,
      // "Close" closes the locked app = back to the home screen, as on Android.
      secondaryButtonLabel: ShieldConfiguration.Label(
        text: snapshot.text("lockHome", "Go to home screen"), color: Palette.primaryInk))
  }

  /// Design tokens from lib/core/utils/style.dart.
  private enum Palette {
    static let primary = UIColor(red: 0x89 / 255, green: 0xCF / 255, blue: 0xF0 / 255, alpha: 1)
    static let primaryInk = UIColor(red: 0x2B / 255, green: 0x8B / 255, blue: 0xC6 / 255, alpha: 1)
    static let onPrimary = UIColor(red: 0x0B / 255, green: 0x25 / 255, blue: 0x40 / 255, alpha: 1)
    static let ink = UIColor(red: 0x0F / 255, green: 0x1B / 255, blue: 0x2D / 255, alpha: 1)
    static let inkSoft = UIColor(red: 0x5B / 255, green: 0x6B / 255, blue: 0x80 / 255, alpha: 1)
    static let peach = UIColor(red: 0xFF / 255, green: 0xEE / 255, blue: 0xE3 / 255, alpha: 1)
  }
}

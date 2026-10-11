/// OS permission requests needed by Sinkly.
///
/// MOCK for now. Native wiring plan (via a MethodChannel / Pigeon plugin):
///  * iOS  — `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
///           from the FamilyControls framework (requires the Family Controls
///           entitlement), then ManagedSettings/DeviceActivity for locking.
///  * Android — Usage Access (`Settings.ACTION_USAGE_ACCESS_SETTINGS`) plus an
///           Accessibility Service or overlay to block selected packages.
///  * Notifications — `firebase_messaging` / `flutter_local_notifications`.
abstract class DevicePermissionsDataSource {
  Future<bool> requestScreenTimeAuthorization();
  Future<bool> requestNotificationPermission();
}

class MockDevicePermissionsDataSource implements DevicePermissionsDataSource {
  @override
  Future<bool> requestScreenTimeAuthorization() async {
    // Simulates the system sheet round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

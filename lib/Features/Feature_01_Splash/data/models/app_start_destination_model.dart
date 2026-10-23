/// Where the app goes once the splash animation ends.
///
/// The paywall is strict, so onboarding only completes after a purchase.
/// After that: Home while subscribed, the paywall once the store confirms
/// the subscription has ended.
enum AppStartDestination { onboarding, home, paywall }

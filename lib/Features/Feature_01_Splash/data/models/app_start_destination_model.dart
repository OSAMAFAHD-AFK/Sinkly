/// Where the app goes once the splash animation ends.
///
/// The paywall is strict, so onboarding only completes after a purchase:
/// "completed" therefore means "subscribed user" → straight to Home.
enum AppStartDestination { onboarding, home }

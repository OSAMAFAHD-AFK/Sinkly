import XCTest

@testable import Runner

/// The Swift side of the shared lock-rule cases: the very same JSON file as
/// Dart's test/lock_engine_vectors_test.dart and Kotlin's LockEngineTest.
/// (Reads the file from the repository, so run it on a simulator.)
final class SinklyLockEngineTests: XCTestCase {
  private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  private func date(_ value: Any?) -> Date? {
    guard let text = value as? String else { return nil }
    let formatter = DateFormatter()
    formatter.calendar = utc
    formatter.timeZone = utc.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = text.count > 16 ? "yyyy-MM-dd'T'HH:mm:ss" : "yyyy-MM-dd'T'HH:mm"
    return formatter.date(from: text)
  }

  func testSharedCases() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("test/fixtures/lock_engine_vectors.json")
    let root = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    for item in root["cases"] as! [[String: Any]] {
      let name = item["name"] as! String
      let snapshot = SinklySnapshot(
        enabled: true,
        activeSinceMs: date(item["activeSince"])?.epochMilliseconds,
        lastCleanAtMs: date(item["lastCleanAt"])?.epochMilliseconds,
        manualLockAtMs: date(item["manualLockAt"])?.epochMilliseconds,
        days: (item["days"] as! [String: [Int]]),
        strings: [:],
        languageCode: "en")
      let state = SinklyLockEngine.evaluate(snapshot, now: date(item["now"])!, calendar: utc)
      let expect = item["expect"] as! [String: Any]
      XCTAssertEqual(state.locked, expect["locked"] as! Bool, "\(name) · locked")
      XCTAssertEqual(state.lockedSince, date(expect["lockedSince"]), "\(name) · lockedSince")
      XCTAssertEqual(state.nextLockAt, date(expect["nextLockAt"]), "\(name) · nextLockAt")
    }
  }

  func testDinnerStaysAtSixOnDaylightSavingDay() {
    var london = Calendar(identifier: .gregorian)
    london.timeZone = TimeZone(identifier: "Europe/London")!
    let day = london.date(from: DateComponents(year: 2026, month: 3, day: 29))!
    let trigger = SinklyLockEngine.triggers(
      days: [7: [18 * 60]], from: day, to: day.addingTimeInterval(23 * 3600), calendar: london
    ).first!
    XCTAssertEqual(london.component(.hour, from: trigger), 18)
    XCTAssertEqual(london.component(.minute, from: trigger), 0)
  }
}

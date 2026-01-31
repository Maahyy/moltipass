import XCTest
@testable import Moltipass

final class ExtensionsTests: XCTestCase {
    func testRelativeTimeJustNow() {
        let date = Date()
        XCTAssertEqual(date.relativeTime, "just now")
    }

    func testRelativeTimeMinutesAgo() {
        let date = Date().addingTimeInterval(-180) // 3 minutes ago
        XCTAssertEqual(date.relativeTime, "3m ago")
    }

    func testRelativeTimeHoursAgo() {
        let date = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertEqual(date.relativeTime, "2h ago")
    }

    func testRelativeTimeDaysAgo() {
        let date = Date().addingTimeInterval(-172800) // 2 days ago
        XCTAssertEqual(date.relativeTime, "2d ago")
    }
}

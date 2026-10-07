import XCTest
@testable import UnreadBadgeCore

final class BadgeRulesTests: XCTestCase {
    func testUnreadParsingAndFloatingDecision() {
        XCTAssertNil(BadgeRules.unreadValue(from: ""))
        XCTAssertNil(BadgeRules.unreadValue(from: "0"))
        XCTAssertNil(BadgeRules.unreadValue(from: "-"))
        XCTAssertEqual(BadgeRules.unreadValue(from: "99+"), "99+")
        XCTAssertTrue(BadgeRules.shouldFloat([nil, "", "3"]))
        XCTAssertFalse(BadgeRules.shouldFloat([nil, "", "0", "-"]))
    }

    func testUnreadCountAcceptsNumbersAndRejectsInvalidValues() {
        XCTAssertEqual(BadgeRules.unreadCount(from: "12"), 12)
        XCTAssertEqual(BadgeRules.unreadCount(from: "99+"), 99)
        XCTAssertEqual(BadgeRules.unreadCount(from: "0"), 0)
        XCTAssertNil(BadgeRules.unreadCount(from: "-"))
        XCTAssertNil(BadgeRules.unreadCount(from: "unread"))
    }
}

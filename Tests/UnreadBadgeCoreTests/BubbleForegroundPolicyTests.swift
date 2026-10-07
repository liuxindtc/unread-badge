import XCTest
@testable import UnreadBadgeCore

final class BubbleForegroundPolicyTests: XCTestCase {
    func testLightBackgroundUsesDarkForeground() {
        XCTAssertEqual(BubbleForegroundPolicy.style(for: "FFFFFF"), .dark)
    }

    func testDarkBackgroundUsesLightForeground() {
        XCTAssertEqual(BubbleForegroundPolicy.style(for: "101820"), .light)
    }
}

import XCTest
@testable import UnreadBadgeCore

final class VisibleAppPolicyTests: XCTestCase {
    func testHidesOnlyAppsWithoutUnreadWhenEnabled() {
        XCTAssertFalse(VisibleAppPolicy.shouldShowApp(hasUnread: false, hideAppsWithoutUnread: true))
        XCTAssertTrue(VisibleAppPolicy.shouldShowApp(hasUnread: true, hideAppsWithoutUnread: true))
        XCTAssertTrue(VisibleAppPolicy.shouldShowApp(hasUnread: false, hideAppsWithoutUnread: false))
    }
}

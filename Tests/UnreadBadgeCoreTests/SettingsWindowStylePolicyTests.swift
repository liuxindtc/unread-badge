import AppKit
import XCTest
@testable import UnreadBadgeCore

final class SettingsWindowStylePolicyTests: XCTestCase {
    func testSettingsWindowKeepsOnlyTitleAndCloseControls() {
        let style = SettingsWindowStylePolicy.styleMask

        XCTAssertTrue(style.contains(.titled))
        XCTAssertTrue(style.contains(.closable))
        XCTAssertFalse(style.contains(.miniaturizable))
        XCTAssertFalse(style.contains(.resizable))
    }

    func testSettingsWindowDoesNotRetakeFocusAfterPanelRefresh() {
        XCTAssertFalse(SettingsWindowStylePolicy.shouldRetakeFocusAfterPanelRefresh)
        XCTAssertFalse(SettingsWindowStylePolicy.shouldAllowZoom)
        XCTAssertFalse(SettingsWindowStylePolicy.shouldAllowFullScreen)
    }
}

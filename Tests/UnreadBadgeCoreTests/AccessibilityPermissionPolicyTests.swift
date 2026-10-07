import XCTest
@testable import UnreadBadgeCore

final class AccessibilityPermissionPolicyTests: XCTestCase {
    func testRequestWhenUntrustedPromptsAndOpensAccessibilitySettings() {
        XCTAssertEqual(
            AccessibilityPermissionPolicy.actions(isTrusted: false),
            [.prompt, .openSystemSettings]
        )
    }

    func testRequestWhenAlreadyTrustedOnlyRefreshesStatus() {
        XCTAssertEqual(
            AccessibilityPermissionPolicy.actions(isTrusted: true),
            [.refreshStatus]
        )
    }

    func testAccessibilitySettingsURLTargetsPrivacyPane() {
        XCTAssertEqual(
            AccessibilityPermissionPolicy.systemSettingsURL.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }
}

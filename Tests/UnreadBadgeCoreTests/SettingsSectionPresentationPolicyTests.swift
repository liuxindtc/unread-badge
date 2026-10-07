import XCTest
@testable import UnreadBadgeCore

final class SettingsSectionPresentationPolicyTests: XCTestCase {
    func testEverySettingsAreaUsesCardPresentationWithDivider() {
        for area in SettingsArea.allCases {
            XCTAssertEqual(SettingsSectionPresentationPolicy.presentation(for: area), .cardWithDivider)
        }
    }
}

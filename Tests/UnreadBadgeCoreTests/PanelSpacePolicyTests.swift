import XCTest
@testable import UnreadBadgeCore

final class PanelSpacePolicyTests: XCTestCase {
    func testNormalPresentationIsRestrictedToDesktopSpaces() {
        XCTAssertEqual(PanelSpacePolicy.behavior(for: false), .desktopOnly)
    }

    func testFrontPresentationCanAppearInFullScreenSpaces() {
        XCTAssertEqual(PanelSpacePolicy.behavior(for: true), .crossSpaceFront)
    }

    func testOnlyFrontPresentationCanJoinOtherApplications() {
        XCTAssertTrue(PanelSpacePolicy.canJoinOtherApplications(for: true))
        XCTAssertFalse(PanelSpacePolicy.canJoinOtherApplications(for: false))
    }

    func testSwitchingFromDesktopOnlyToFrontPresentationReregistersAcrossSpaces() {
        XCTAssertEqual(
            PanelSpacePolicy.transition(from: .desktopOnly, to: .crossSpaceFront),
            .reregisterAcrossSpaces
        )
    }
}

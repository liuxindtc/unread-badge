import XCTest
@testable import UnreadBadgeCore

final class InstanceLaunchPolicyTests: XCTestCase {
    func testForwardsSettingsRequestWhenAnotherInstanceExists() {
        XCTAssertEqual(
            InstanceLaunchPolicy.action(existingProcessIDs: [101, 202], currentProcessID: 202),
            .forwardSettingsRequest
        )
    }

    func testLaunchesWhenOnlyCurrentInstanceIsPresent() {
        XCTAssertEqual(
            InstanceLaunchPolicy.action(existingProcessIDs: [202], currentProcessID: 202),
            .launch
        )
    }

    func testReopeningAnExistingAppShowsSettingsEvenWithoutVisibleWindows() {
        XCTAssertTrue(InstanceLaunchPolicy.shouldShowSettingsOnReopen(hasVisibleWindows: false))
    }
}

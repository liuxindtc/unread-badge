import XCTest
@testable import UnreadBadgeCore

final class IconSizeStepperTests: XCTestCase {
    func testIncreaseRoundsUpToNextMultipleOfSixteen() {
        XCTAssertEqual(DisplaySettings.increasedIconSize(from: 32), 48)
        XCTAssertEqual(DisplaySettings.increasedIconSize(from: 35), 48)
        XCTAssertEqual(DisplaySettings.increasedIconSize(from: 48), 64)
    }
}

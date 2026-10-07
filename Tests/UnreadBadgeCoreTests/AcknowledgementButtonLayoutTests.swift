import XCTest
@testable import UnreadBadgeCore

final class AcknowledgementButtonLayoutTests: XCTestCase {
    func testReservesBottomSpaceOnlyWhenAcknowledgementButtonIsVisible() {
        XCTAssertEqual(AcknowledgementButtonLayout.contentTopPadding(isVisible: false), 0)
        XCTAssertEqual(AcknowledgementButtonLayout.contentTopPadding(isVisible: true), 0)
        XCTAssertEqual(AcknowledgementButtonLayout.contentBottomPadding(isVisible: false), 0)
        XCTAssertGreaterThanOrEqual(AcknowledgementButtonLayout.contentBottomPadding(isVisible: true), 40)
    }

    func testUsesCompactContinuousCornerRadiusForFloatingAcknowledgementButton() {
        XCTAssertEqual(AcknowledgementButtonLayout.cornerRadius, 10)
    }

    func testUsesContrastingTextForEachSystemAppearance() {
        XCTAssertEqual(AcknowledgementButtonLayout.foregroundStyle(forDarkAppearance: false), .dark)
        XCTAssertEqual(AcknowledgementButtonLayout.foregroundStyle(forDarkAppearance: true), .light)
    }

    func testUsesConfiguredOpacityWhetherTheBubbleIsFocusedOrNot() {
        XCTAssertEqual(AcknowledgementButtonLayout.backgroundOpacity(isBubbleFocused: true, configuredOpacity: 0.4), 0.4)
        XCTAssertEqual(AcknowledgementButtonLayout.backgroundOpacity(isBubbleFocused: false, configuredOpacity: 0.4), 0.4)
    }

    func testHighlightsAcknowledgementButtonWithoutMovingItWhileHovered() {
        XCTAssertEqual(AcknowledgementButtonLayout.verticalOffset(isHovered: false), 0)
        XCTAssertEqual(AcknowledgementButtonLayout.verticalOffset(isHovered: true), 0)
        XCTAssertEqual(AcknowledgementButtonLayout.shadowRadius(isHovered: false), 4)
        XCTAssertEqual(AcknowledgementButtonLayout.shadowRadius(isHovered: true), 7)
        XCTAssertEqual(AcknowledgementButtonLayout.borderOpacity(isHovered: false), 0.38)
        XCTAssertEqual(AcknowledgementButtonLayout.borderOpacity(isHovered: true), 0.62)
    }
}

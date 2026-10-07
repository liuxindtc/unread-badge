import XCTest
@testable import UnreadBadgeCore

final class InteractionPolicyTests: XCTestCase {
    func testSettingsShortcutUsesPhysicalCommaKeyWithCommand() {
        XCTAssertTrue(KeyboardShortcutPolicy.isSettingsShortcut(commandPressed: true, keyCode: 43))
        XCTAssertFalse(KeyboardShortcutPolicy.isSettingsShortcut(commandPressed: false, keyCode: 43))
        XCTAssertFalse(KeyboardShortcutPolicy.isSettingsShortcut(commandPressed: true, keyCode: 42))
    }

    func testActivatingAnApplicationRestoresItBeforeBringingWindowsForward() {
        XCTAssertTrue(AppActivationPolicy.shouldUnhideBeforeActivating)
        XCTAssertTrue(AppActivationPolicy.shouldRestoreMinimizedWindows)
    }

    func testInactivePanelAcceptsTheFirstClickOnAnInteractiveControl() {
        XCTAssertTrue(FloatingPanelInteractionPolicy.shouldAcceptFirstMouse)
        XCTAssertTrue(FloatingPanelInteractionPolicy.shouldPromotePanelBeforeDispatchingFirstClick)
        XCTAssertTrue(FloatingPanelInteractionPolicy.shouldDeferFocusRefreshWhileDispatchingFirstClick)
    }

    func testFloatingPanelBackgroundCanMoveTheWindow() {
        XCTAssertTrue(FloatingPanelInteractionPolicy.shouldAllowBackgroundWindowDragging)
    }

    func testDraggingAnyBubblePointOffsetsTheWindowFromItsStartingOrigin() {
        let origin = FloatingPanelDragMovement.origin(
            startOrigin: CGPoint(x: 600, y: 356),
            startMouseLocation: CGPoint(x: 700, y: 500),
            currentMouseLocation: CGPoint(x: 760, y: 540)
        )

        XCTAssertEqual(origin, CGPoint(x: 660, y: 396))
    }

    func testFocusRefreshWaitsUntilTheInitialMouseInteractionFinishes() {
        var interaction = FloatingPanelInteractionState()

        interaction.beginInitialMouseInteraction()
        XCTAssertFalse(interaction.shouldRefreshForFocusChange)

        interaction.endInitialMouseInteraction()
        XCTAssertTrue(interaction.shouldRefreshForFocusChange)
    }

    func testDraggingSuppressesTheButtonActionUntilTheNextMouseInteraction() {
        var interaction = FloatingPanelInteractionState()

        interaction.beginInitialMouseInteraction()
        XCTAssertTrue(interaction.shouldDispatchClickAction)

        interaction.markAsDragged()
        XCTAssertFalse(interaction.shouldDispatchClickAction)

        interaction.endInitialMouseInteraction()
        interaction.beginInitialMouseInteraction()
        XCTAssertTrue(interaction.shouldDispatchClickAction)
    }

    func testAppActivationAreaUsesPointingHandCursor() {
        XCTAssertTrue(PointerCursorPolicy.shouldUsePointingHandForAppActivation)
    }

    func testApplicationRowHighlightsWithoutMovingWhileHovered() {
        XCTAssertEqual(PointerCursorPolicy.applicationRowVerticalOffset(isHovered: false), 0)
        XCTAssertEqual(PointerCursorPolicy.applicationRowVerticalOffset(isHovered: true), 0)
        XCTAssertEqual(PointerCursorPolicy.applicationRowBackgroundOpacity(isHovered: false), 0)
        XCTAssertEqual(PointerCursorPolicy.applicationRowBackgroundOpacity(isHovered: true), 0.12)
    }

    func testFloatingPanelDisablesUserResizingAndZooming() {
        XCTAssertFalse(FloatingPanelInteractionPolicy.shouldAllowUserResizing)
        XCTAssertFalse(FloatingPanelInteractionPolicy.shouldAllowZoom)
        XCTAssertFalse(FloatingPanelInteractionPolicy.shouldAllowFullScreen)
    }
}

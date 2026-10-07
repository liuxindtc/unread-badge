import AppKit

public enum FloatingPanelInteractionPolicy {
    public static let shouldAcceptFirstMouse = true
    public static let shouldPromotePanelBeforeDispatchingFirstClick = true
    public static let shouldDeferFocusRefreshWhileDispatchingFirstClick = true
    public static let shouldAllowBackgroundWindowDragging = true
    public static let shouldAllowUserResizing = false
    public static let shouldAllowZoom = false
    public static let shouldAllowFullScreen = false
}

public struct FloatingPanelInteractionState: Equatable, Sendable {
    public private(set) var isInitialMouseInteractionActive = false
    public private(set) var didDrag = false

    public init() {}

    public var shouldRefreshForFocusChange: Bool {
        !isInitialMouseInteractionActive
    }

    public var shouldDispatchClickAction: Bool {
        !didDrag
    }

    public mutating func beginInitialMouseInteraction() {
        isInitialMouseInteractionActive = true
        didDrag = false
    }

    public mutating func markAsDragged() {
        didDrag = true
    }

    public mutating func endInitialMouseInteraction() {
        isInitialMouseInteractionActive = false
    }
}

public enum FloatingPanelDragMovement {
    public static func origin(startOrigin: CGPoint, startMouseLocation: CGPoint, currentMouseLocation: CGPoint) -> CGPoint {
        CGPoint(
            x: startOrigin.x + currentMouseLocation.x - startMouseLocation.x,
            y: startOrigin.y + currentMouseLocation.y - startMouseLocation.y
        )
    }
}

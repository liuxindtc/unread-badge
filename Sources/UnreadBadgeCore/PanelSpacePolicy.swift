import Foundation

public enum PanelSpaceBehavior: Equatable, Sendable {
    case crossSpaceFront
    case desktopOnly
}

public enum PanelSpaceTransition: Equatable, Sendable {
    case unchanged
    case reregisterAcrossSpaces
}

public enum PanelSpacePolicy {
    public static func behavior(for isFrontPresentation: Bool) -> PanelSpaceBehavior {
        isFrontPresentation ? .crossSpaceFront : .desktopOnly
    }

    public static func canJoinOtherApplications(for isFrontPresentation: Bool) -> Bool {
        isFrontPresentation
    }

    public static func transition(from current: PanelSpaceBehavior?, to target: PanelSpaceBehavior) -> PanelSpaceTransition {
        guard target == .crossSpaceFront, current != .crossSpaceFront else { return .unchanged }
        return .reregisterAcrossSpaces
    }
}

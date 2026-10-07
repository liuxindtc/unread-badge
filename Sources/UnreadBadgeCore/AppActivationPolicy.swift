import Foundation

public enum AppActivationPolicy {
    public static let shouldUnhideBeforeActivating = true
    public static let shouldRestoreMinimizedWindows = true
}

public enum AccessibilityPermissionAction: Equatable, Sendable {
    case prompt
    case openSystemSettings
    case refreshStatus
}

public enum AccessibilityPermissionPolicy {
    public static let systemSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    public static func actions(isTrusted: Bool) -> [AccessibilityPermissionAction] {
        isTrusted ? [.refreshStatus] : [.prompt, .openSystemSettings]
    }
}

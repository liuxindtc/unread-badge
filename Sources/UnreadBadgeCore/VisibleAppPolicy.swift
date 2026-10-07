import Foundation

public enum VisibleAppPolicy {
    public static func shouldShowApp(hasUnread: Bool, hideAppsWithoutUnread: Bool) -> Bool {
        hasUnread || !hideAppsWithoutUnread
    }
}

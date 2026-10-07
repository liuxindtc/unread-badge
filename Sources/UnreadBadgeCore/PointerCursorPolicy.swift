import Foundation

public enum PointerCursorPolicy {
    public static let shouldUsePointingHandForAppActivation = true

    public static func applicationRowVerticalOffset(isHovered: Bool) -> Double {
        0
    }

    public static func applicationRowBackgroundOpacity(isHovered: Bool) -> Double {
        isHovered ? 0.12 : 0
    }
}

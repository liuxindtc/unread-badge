import AppKit

public enum AcknowledgementButtonLayout {
    public static let cornerRadius: Double = 10

    public static func foregroundStyle(forDarkAppearance isDarkAppearance: Bool) -> BubbleForegroundStyle {
        isDarkAppearance ? .light : .dark
    }

    public static func contentTopPadding(isVisible: Bool) -> Double {
        0
    }

    public static func contentBottomPadding(isVisible: Bool) -> Double {
        isVisible ? 44 : 0
    }

    public static func backgroundOpacity(isBubbleFocused: Bool, configuredOpacity: Double) -> Double {
        configuredOpacity
    }

    public static func verticalOffset(isHovered: Bool) -> Double {
        0
    }

    public static func shadowRadius(isHovered: Bool) -> Double {
        isHovered ? 7 : 4
    }

    public static func borderOpacity(isHovered: Bool) -> Double {
        isHovered ? 0.62 : 0.38
    }
}

public enum SettingsArea: CaseIterable, Sendable {
    case permission
    case appearance
    case applicationList
}

public enum SettingsSectionPresentation: Equatable, Sendable {
    case cardWithDivider
}

public enum SettingsSectionPresentationPolicy {
    public static func presentation(for area: SettingsArea) -> SettingsSectionPresentation {
        .cardWithDivider
    }
}

public enum SettingsWindowStylePolicy {
    public static let styleMask: NSWindow.StyleMask = [.titled, .closable]
    public static let shouldRetakeFocusAfterPanelRefresh = false
    public static let shouldAllowZoom = false
    public static let shouldAllowFullScreen = false
}

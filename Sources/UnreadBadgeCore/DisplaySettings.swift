import Foundation

public struct DisplaySettings: Codable, Equatable, Sendable {
    public var iconSize: Double
    public var backgroundOpacity: Double
    public var blurIntensity: Double
    public var topMode: TopMode
    public var backgroundColorHex: String
    public var hideAppsWithoutUnread: Bool
    public var acknowledgementButtonText: String

    public init(iconSize: Double = 32, backgroundOpacity: Double = 0.5, blurIntensity: Double = 0, topMode: TopMode = .unreadMessage, backgroundColorHex: String = "000000", hideAppsWithoutUnread: Bool = false, acknowledgementButtonText: String = "晓得了") {
        self.iconSize = iconSize
        self.backgroundOpacity = backgroundOpacity
        self.blurIntensity = blurIntensity
        self.topMode = topMode
        self.backgroundColorHex = backgroundColorHex
        self.hideAppsWithoutUnread = hideAppsWithoutUnread
        self.acknowledgementButtonText = acknowledgementButtonText
    }

    public func shouldFloat(rawValues: [String?], tracker: BadgePresentationTracker) -> Bool {
        tracker.shouldFloat(mode: topMode, hasUnreadMessages: BadgeRules.shouldFloat(rawValues))
    }

    public func shouldAutomaticallyShowPanel(rawValues: [String?], tracker: BadgePresentationTracker) -> Bool {
        shouldFloat(rawValues: rawValues, tracker: tracker)
    }

    public static func increasedIconSize(from value: Double) -> Double {
        let rounded = value.truncatingRemainder(dividingBy: 16) == 0 ? value + 16 : ceil(value / 16) * 16
        return min(128, rounded)
    }
    public static func decreasedIconSize(from value: Double) -> Double { max(16, floor((value - 0.001) / 16) * 16) }

    private enum CodingKeys: String, CodingKey {
        case iconSize, backgroundOpacity, blurIntensity, topMode, backgroundColorHex, hideAppsWithoutUnread, acknowledgementButtonText, alwaysOnTop
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iconSize = try container.decodeIfPresent(Double.self, forKey: .iconSize) ?? 32
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? 0.5
        blurIntensity = try container.decodeIfPresent(Double.self, forKey: .blurIntensity) ?? 0
        backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "000000"
        hideAppsWithoutUnread = try container.decodeIfPresent(Bool.self, forKey: .hideAppsWithoutUnread) ?? false
        acknowledgementButtonText = try container.decodeIfPresent(String.self, forKey: .acknowledgementButtonText) ?? "晓得了"
        if let decodedMode = try container.decodeIfPresent(TopMode.self, forKey: .topMode) {
            topMode = decodedMode
        } else {
            topMode = (try container.decodeIfPresent(Bool.self, forKey: .alwaysOnTop) ?? false) ? .always : .unreadMessage
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iconSize, forKey: .iconSize)
        try container.encode(backgroundOpacity, forKey: .backgroundOpacity)
        try container.encode(blurIntensity, forKey: .blurIntensity)
        try container.encode(topMode, forKey: .topMode)
        try container.encode(backgroundColorHex, forKey: .backgroundColorHex)
        try container.encode(hideAppsWithoutUnread, forKey: .hideAppsWithoutUnread)
        try container.encode(acknowledgementButtonText, forKey: .acknowledgementButtonText)
    }
}

import Foundation

public enum BadgeRules {
    public static func unreadCount(from raw: String?) -> Int? {
        guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        let digits = value.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    public static func unreadValue(from raw: String?) -> String? {
        guard let count = unreadCount(from: raw), count > 0 else { return nil }
        return raw?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func shouldFloat(_ rawValues: [String?]) -> Bool {
        rawValues.contains { (unreadCount(from: $0) ?? 0) > 0 }
    }
}

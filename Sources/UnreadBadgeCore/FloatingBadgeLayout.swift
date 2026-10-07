import Foundation

public struct BadgeRow: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let value: String?
    public let iconSize: Double
    public init(name: String, value: String?, iconSize: Double) { self.name = name; self.value = value; self.iconSize = iconSize }
}

public enum FloatingBadgeLayout {
    public static func emptyStateSize() -> CGSize { CGSize(width: 180, height: 72) }

    public static func size(for rows: [BadgeRow]) -> CGSize {
        let icon = rows.map(\.iconSize).max() ?? 32
        let nameWidth = rows.map { min(220, max(72, Double($0.name.count) * 14)) }.max() ?? 72
        let valueWidth = rows.map { max(30, Double(($0.value ?? "—").count) * 10 + 14) }.max() ?? 30
        let width = 16 + icon + 12 + nameWidth + 12 + valueWidth + 16
        let rowHeight = max(icon + 12, 44)
        let height = Double(max(1, rows.count)) * rowHeight + 16
        return CGSize(width: width, height: height)
    }
}

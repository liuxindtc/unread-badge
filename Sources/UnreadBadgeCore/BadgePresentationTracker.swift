import Foundation

public enum TopMode: String, CaseIterable, Codable, Sendable {
    case always
    case unreadMessage
    case newMessage
}

public struct BadgePresentationTracker: Sendable {
    private var previousCounts: [String: Int]?
    private var pendingChange = false
    private var acknowledgedCurrentValues = false
    private var increasedAppIDs = Set<String>()

    public var hasUnacknowledgedChange: Bool { pendingChange }
    public var hasAcknowledgedCurrentValues: Bool { acknowledgedCurrentValues }

    public init() {}

    @discardableResult
    public mutating func observe(counts: [String: Int]) -> [String] {
        defer { previousCounts = counts }
        guard !counts.isEmpty else {
            pendingChange = false
            increasedAppIDs.removeAll()
            return []
        }
        guard let previousCounts else { return [] }
        let changed = counts.keys.filter { counts[$0, default: 0] > previousCounts[$0, default: 0] }.sorted()
        guard !changed.isEmpty else { return [] }
        pendingChange = true
        increasedAppIDs.formUnion(changed)
        return changed
    }

    public mutating func acknowledgeCurrentValues() {
        pendingChange = false
        acknowledgedCurrentValues = true
        increasedAppIDs.removeAll()
    }

    public mutating func reset(counts: [String: Int]) {
        previousCounts = counts
        pendingChange = false
        acknowledgedCurrentValues = false
        increasedAppIDs.removeAll()
    }

    @discardableResult
    public mutating func enterNewMessageMode(counts: [String: Int]) -> [String] {
        previousCounts = counts
        pendingChange = !counts.isEmpty
        acknowledgedCurrentValues = false
        increasedAppIDs = Set(counts.keys)
        return counts.keys.sorted()
    }

    public func shouldUseMutedBadge(for appID: String) -> Bool {
        acknowledgedCurrentValues && !increasedAppIDs.contains(appID)
    }

    public func shouldFloat(mode: TopMode, hasUnreadMessages: Bool) -> Bool {
        switch mode {
        case .always: true
        case .unreadMessage: hasUnreadMessages
        case .newMessage: pendingChange
        }
    }
}

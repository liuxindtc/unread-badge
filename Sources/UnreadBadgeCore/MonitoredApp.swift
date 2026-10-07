import Foundation

public struct MonitoredApp: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var dockName: String
    public var displayName: String
    public var iconOverridePath: String?
    public var bundlePath: String?
    public var iconSize: Double
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        dockName: String,
        displayName: String,
        iconOverridePath: String? = nil,
        bundlePath: String? = nil,
        iconSize: Double = 32,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.dockName = dockName
        self.displayName = displayName
        self.iconOverridePath = iconOverridePath
        self.bundlePath = bundlePath
        self.iconSize = iconSize
        self.sortOrder = sortOrder
    }
}

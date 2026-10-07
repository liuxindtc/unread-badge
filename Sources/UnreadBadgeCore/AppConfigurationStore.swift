import Foundation

public final class AppConfigurationStore {
    private let defaults: UserDefaults
    private let appsKey = "monitoredApps"
    private let originKey = "floatingWindowOrigin"
    private let settingsKey = "displaySettings"
    private let settingsWindowRequestKey = "settingsWindowRequest"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> [MonitoredApp] {
        guard let data = defaults.data(forKey: appsKey),
              let apps = try? JSONDecoder().decode([MonitoredApp].self, from: data)
        else { return [] }
        return apps.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func save(_ apps: [MonitoredApp]) {
        defaults.set(try? JSONEncoder().encode(apps), forKey: appsKey)
    }

    public func loadDisplaySettings() -> DisplaySettings {
        guard let data = defaults.data(forKey: settingsKey), let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) else { return DisplaySettings() }
        return settings
    }

    public func saveDisplaySettings(_ settings: DisplaySettings) {
        defaults.set(try? JSONEncoder().encode(settings), forKey: settingsKey)
    }

    public var settingsWindowRequestToken: String? { defaults.string(forKey: settingsWindowRequestKey) }

    public func requestSettingsWindow() { defaults.set(UUID().uuidString, forKey: settingsWindowRequestKey) }

    public var windowOrigin: CGPoint? {
        get {
            guard let dictionary = defaults.dictionary(forKey: originKey),
                  let x = dictionary["x"] as? Double,
                  let y = dictionary["y"] as? Double
            else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: originKey)
                return
            }
            defaults.set(["x": newValue.x, "y": newValue.y], forKey: originKey)
        }
    }
}

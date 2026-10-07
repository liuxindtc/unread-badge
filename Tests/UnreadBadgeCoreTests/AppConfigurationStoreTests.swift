import XCTest
@testable import UnreadBadgeCore

final class AppConfigurationStoreTests: XCTestCase {
    func testStoreRestoresAppsAndWindowOrigin() {
        let defaults = UserDefaults(suiteName: "AppConfigurationStoreTests")!
        defaults.removePersistentDomain(forName: "AppConfigurationStoreTests")
        let store = AppConfigurationStore(defaults: defaults)
        let apps = [MonitoredApp(dockName: "飞书", displayName: "飞书", iconSize: 40)]

        store.save(apps)
        store.windowOrigin = .init(x: 123, y: 456)

        XCTAssertEqual(store.load(), apps)
        XCTAssertEqual(store.windowOrigin, .init(x: 123, y: 456))
    }
}

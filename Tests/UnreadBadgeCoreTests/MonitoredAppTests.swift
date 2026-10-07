import XCTest
@testable import UnreadBadgeCore

final class MonitoredAppTests: XCTestCase {
    func testConfigurationRoundTripPreservesCustomPresentation() throws {
        let app = MonitoredApp(
            dockName: "微信",
            displayName: "客户微信",
            iconOverridePath: "/tmp/wechat.png",
            iconSize: 36,
            sortOrder: 2
        )

        let decoded = try JSONDecoder().decode(
            MonitoredApp.self,
            from: JSONEncoder().encode(app)
        )

        XCTAssertEqual(decoded, app)
    }
}

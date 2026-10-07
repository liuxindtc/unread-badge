import XCTest
@testable import UnreadBadgeCore

final class ApplicationPickerOptionsTests: XCTestCase {
    func testRunningOptionsExcludeCurrentApplicationAndKeepSelectableAppDetails() {
        let options = ApplicationPickerOptions.runningOptions(
            from: [
                RunningApplicationOption(displayName: "UnreadBadge", bundleIdentifier: "com.blaine.UnreadBadge", bundlePath: "/Applications/UnreadBadge.app"),
                RunningApplicationOption(displayName: "飞书", bundleIdentifier: "com.larksuite.suite", bundlePath: "/Applications/Lark.app"),
                RunningApplicationOption(displayName: "微信", bundleIdentifier: "com.tencent.xinWeChat", bundlePath: "/Applications/WeChat.app")
            ],
            currentBundleIdentifier: "com.blaine.UnreadBadge"
        )

        XCTAssertEqual(options.map(\.displayName), ["飞书", "微信"])
        XCTAssertEqual(options.first(where: { $0.displayName == "飞书" })?.bundlePath, "/Applications/Lark.app")
    }
}

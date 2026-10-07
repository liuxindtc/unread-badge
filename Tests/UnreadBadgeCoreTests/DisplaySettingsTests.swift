import XCTest
@testable import UnreadBadgeCore

final class DisplaySettingsTests: XCTestCase {
    func testDefaultsToSemiTransparentBlackBackground() {
        let settings = DisplaySettings()

        XCTAssertEqual(settings.backgroundColorHex, "000000")
        XCTAssertEqual(settings.backgroundOpacity, 0.5)
    }

    func testTopModesUseExpectedFloatingRules() {
        var settings = DisplaySettings()
        let tracker = BadgePresentationTracker()
        XCTAssertFalse(settings.shouldFloat(rawValues: [nil, "0"], tracker: tracker))
        settings.topMode = .always
        XCTAssertTrue(settings.shouldFloat(rawValues: [nil, "0"], tracker: tracker))

        settings.topMode = .unreadMessage
        XCTAssertTrue(settings.shouldFloat(rawValues: [nil, "3"], tracker: tracker))
    }

    func testAutomaticallyShowsPanelOnlyForUnreadOrAlwaysOnTop() {
        var settings = DisplaySettings()
        let tracker = BadgePresentationTracker()
        XCTAssertFalse(settings.shouldAutomaticallyShowPanel(rawValues: [nil, "0", "-"], tracker: tracker))
        XCTAssertTrue(settings.shouldAutomaticallyShowPanel(rawValues: [nil, "4"], tracker: tracker))

        settings.topMode = .always
        XCTAssertTrue(settings.shouldAutomaticallyShowPanel(rawValues: [nil, "0", "-"], tracker: tracker))
    }

    func testSettingsRoundTripPreservesGlobalAppearance() throws {
        let settings = DisplaySettings(iconSize: 42, backgroundOpacity: 0.7, blurIntensity: 0.5, topMode: .newMessage, hideAppsWithoutUnread: true, acknowledgementButtonText: "我知道了")
        XCTAssertEqual(try JSONDecoder().decode(DisplaySettings.self, from: JSONEncoder().encode(settings)), settings)
    }

    func testDefaultsAcknowledgementButtonTextForExistingConfiguration() throws {
        let data = #"{"iconSize":32,"backgroundOpacity":0.5,"blurIntensity":0,"topMode":"newMessage","backgroundColorHex":"000000"}"#.data(using: .utf8)!

        XCTAssertEqual(try JSONDecoder().decode(DisplaySettings.self, from: data).acknowledgementButtonText, "晓得了")
    }

    func testLegacyAlwaysOnTopSettingMigratesToAlwaysMode() throws {
        let data = #"{"iconSize":32,"backgroundOpacity":0.82,"blurIntensity":0,"alwaysOnTop":true,"backgroundColorHex":"FFFFFF"}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(DisplaySettings.self, from: data).topMode, .always)
    }
}

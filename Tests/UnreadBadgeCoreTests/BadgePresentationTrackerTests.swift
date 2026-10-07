import XCTest
@testable import UnreadBadgeCore

final class BadgePresentationTrackerTests: XCTestCase {
    func testEnteringNewMessageModeTreatsCurrentUnreadCountsAsPending() {
        var tracker = BadgePresentationTracker()
        tracker.reset(counts: ["feishu": 4, "wecom": 1])

        XCTAssertEqual(tracker.enterNewMessageMode(counts: ["feishu": 4, "wecom": 1]), ["feishu", "wecom"])
        XCTAssertTrue(tracker.hasUnacknowledgedChange)
        XCTAssertFalse(tracker.hasAcknowledgedCurrentValues)
        XCTAssertFalse(tracker.shouldUseMutedBadge(for: "feishu"))
        XCTAssertTrue(tracker.shouldFloat(mode: .newMessage, hasUnreadMessages: true))
    }

    func testNewMessageModeFloatsOnlyAfterAnUnreadCountIncrease() {
        var tracker = BadgePresentationTracker()

        XCTAssertEqual(tracker.observe(counts: ["feishu": 2]), [])
        XCTAssertEqual(tracker.observe(counts: ["feishu": 1]), [])
        XCTAssertEqual(tracker.observe(counts: ["feishu": 3]), ["feishu"])
        XCTAssertTrue(tracker.hasUnacknowledgedChange)
        XCTAssertTrue(tracker.shouldFloat(mode: .newMessage, hasUnreadMessages: true))
    }

    func testAcknowledgementMutesExistingBadgesUntilThatAppIncreasesAgain() {
        var tracker = BadgePresentationTracker()

        _ = tracker.observe(counts: ["feishu": 2, "wecom": 1])
        tracker.acknowledgeCurrentValues()
        XCTAssertTrue(tracker.hasAcknowledgedCurrentValues)
        XCTAssertTrue(tracker.shouldUseMutedBadge(for: "feishu"))
        XCTAssertTrue(tracker.shouldUseMutedBadge(for: "wecom"))

        XCTAssertEqual(tracker.observe(counts: ["feishu": 3, "wecom": 1]), ["feishu"])
        XCTAssertFalse(tracker.shouldUseMutedBadge(for: "feishu"))
        XCTAssertTrue(tracker.shouldUseMutedBadge(for: "wecom"))
        XCTAssertTrue(tracker.hasUnacknowledgedChange)
    }

    func testOtherTopModesUseTheirOwnRules() {
        var tracker = BadgePresentationTracker()
        _ = tracker.observe(counts: [:])

        XCTAssertTrue(tracker.shouldFloat(mode: .always, hasUnreadMessages: false))
        XCTAssertTrue(tracker.shouldFloat(mode: .unreadMessage, hasUnreadMessages: true))
        XCTAssertFalse(tracker.shouldFloat(mode: .unreadMessage, hasUnreadMessages: false))
    }

    func testClearingUnreadMessagesDoesNotTriggerOrKeepNewMessageFloating() {
        var tracker = BadgePresentationTracker()

        XCTAssertEqual(tracker.observe(counts: ["feishu": 3]), [])
        XCTAssertEqual(tracker.observe(counts: [:]), [])
        XCTAssertFalse(tracker.hasUnacknowledgedChange)
    }

    func testLosingAllUnreadCountsClearsAnOutstandingNewMessageNotification() {
        var tracker = BadgePresentationTracker()

        XCTAssertEqual(tracker.observe(counts: ["feishu": 1]), [])
        XCTAssertEqual(tracker.observe(counts: ["feishu": 2]), ["feishu"])
        XCTAssertTrue(tracker.hasUnacknowledgedChange)

        XCTAssertEqual(tracker.observe(counts: [:]), [])
        XCTAssertFalse(tracker.hasUnacknowledgedChange)
        XCTAssertFalse(tracker.shouldFloat(mode: .newMessage, hasUnreadMessages: false))
    }
}

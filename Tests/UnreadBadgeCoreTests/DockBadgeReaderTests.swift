import XCTest
@testable import UnreadBadgeCore

final class DockBadgeReaderTests: XCTestCase {
    func testBadgeValueConvertsNumericAccessibilityValueToText() {
        XCTAssertEqual(DockBadgeReader.badgeText(from: NSNumber(value: 7)), "7")
    }

    func testReadReturnsUnavailableWhenAccessibilityIsNotTrusted() {
        let reader = DockBadgeReader(isTrusted: { false })
        XCTAssertEqual(reader.readBadge(dockName: "微信"), .unavailable(.accessibilityPermissionRequired))
    }

    func testReadDoesNotInvokeAccessibilityReaderWithoutPermission() {
        var accessibilityWasUsed = false
        let reader = DockBadgeReader(
            isTrusted: { false },
            readBadgeWhenTrusted: { _ in
                accessibilityWasUsed = true
                return .value("1")
            }
        )

        XCTAssertEqual(reader.readBadge(dockName: "ChatGPT"), .unavailable(.accessibilityPermissionRequired))
        XCTAssertFalse(accessibilityWasUsed)
    }

    func testReadUsesAccessibilityReaderWhenPermissionIsGranted() {
        var receivedName: String?
        let reader = DockBadgeReader(
            isTrusted: { true },
            readBadgeWhenTrusted: { name in
                receivedName = name
                return .value("4")
            }
        )

        XCTAssertEqual(reader.readBadge(dockName: "微信"), .value("4"))
        XCTAssertEqual(receivedName, "微信")
    }

}

final class BadgePollingCoordinatorTests: XCTestCase {
    func testPollReadsOffMainThreadAndCompletesOnMainThread() {
        let completed = expectation(description: "poll completed")
        var readerRanOnMainThread = true
        let coordinator = BadgePollingCoordinator { name in
            readerRanOnMainThread = Thread.isMainThread
            return .value(name == "微信" ? "6" : nil)
        }

        XCTAssertTrue(coordinator.poll(dockNames: ["微信"]) { statuses in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertFalse(readerRanOnMainThread)
            XCTAssertEqual(statuses, [.value("6")])
            completed.fulfill()
        })

        wait(for: [completed], timeout: 2)
    }

    func testPollRejectsOverlapUntilCurrentReadCompletes() {
        let readerStarted = expectation(description: "reader started")
        let completed = expectation(description: "poll completed")
        let releaseReader = DispatchSemaphore(value: 0)
        let coordinator = BadgePollingCoordinator { _ in
            readerStarted.fulfill()
            releaseReader.wait()
            return .value("1")
        }

        XCTAssertTrue(coordinator.poll(dockNames: ["微信"]) { _ in completed.fulfill() })
        wait(for: [readerStarted], timeout: 2)
        XCTAssertFalse(coordinator.poll(dockNames: ["飞书"]) { _ in
            XCTFail("overlapping poll must not complete")
        })
        releaseReader.signal()
        wait(for: [completed], timeout: 2)
    }
}

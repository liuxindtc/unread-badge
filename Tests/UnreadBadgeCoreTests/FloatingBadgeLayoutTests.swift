import XCTest
@testable import UnreadBadgeCore

final class FloatingBadgeLayoutTests: XCTestCase {
    func testPanelHeightGrowsWithRowsAndWidthGrowsWithName() {
        let one = FloatingBadgeLayout.size(for: [.init(name: "微信", value: "1", iconSize: 32)])
        let two = FloatingBadgeLayout.size(for: [.init(name: "微信", value: "1", iconSize: 32), .init(name: "飞书", value: "2", iconSize: 32)])
        let long = FloatingBadgeLayout.size(for: [.init(name: "非常长的自定义应用名称", value: "1", iconSize: 32)])
        XCTAssertGreaterThan(two.height, one.height)
        XCTAssertGreaterThan(long.width, one.width)
    }

    func testEmptyStateHasDedicatedCenteredMessageSize() {
        let size = FloatingBadgeLayout.emptyStateSize()
        XCTAssertGreaterThanOrEqual(size.width, 120)
        XCTAssertGreaterThanOrEqual(size.height, 56)
    }
}

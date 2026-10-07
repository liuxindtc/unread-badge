import ApplicationServices
import AppKit
import Foundation
import OSLog

public enum BadgeReadError: Equatable, Sendable {
    case accessibilityPermissionRequired
    case dockUnavailable
    case applicationNotFound
}

public enum BadgeReadStatus: Equatable, Sendable {
    case value(String?)
    case unavailable(BadgeReadError)
}

public final class DockBadgeReader {
    private static let logger = Logger(subsystem: "blaine.unreadbadge", category: "badge-reader")
    private let isTrusted: () -> Bool
    private let readBadgeWhenTrusted: (String) -> BadgeReadStatus

    public init(
        isTrusted: @escaping () -> Bool = { AXIsProcessTrusted() },
        readBadgeWhenTrusted: ((String) -> BadgeReadStatus)? = nil
    ) {
        self.isTrusted = isTrusted
        self.readBadgeWhenTrusted = readBadgeWhenTrusted ?? { dockName in
            DockBadgeReader.readBadgeUsingAccessibility(dockName: dockName)
        }
    }

    public func readBadge(dockName: String) -> BadgeReadStatus {
        guard isTrusted() else { return .unavailable(.accessibilityPermissionRequired) }
        return readBadgeWhenTrusted(dockName)
    }

    private static func readBadgeUsingAccessibility(dockName: String) -> BadgeReadStatus {
        guard let dockPID = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.dock" })?.processIdentifier else {
            logger.error("AX Dock process unavailable for \(dockName, privacy: .public)")
            return .unavailable(.dockUnavailable)
        }
        guard let item = findElement(AXUIElementCreateApplication(dockPID), titled: dockName) else {
            logger.error("AX Dock item not found for \(dockName, privacy: .public)")
            return .unavailable(.applicationNotFound)
        }
        var badge: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(item, "AXStatusLabel" as CFString, &badge)
        guard error == .success else {
            logger.error("AXStatusLabel failed for \(dockName, privacy: .public), AXError=\(error.rawValue)")
            return .value(nil)
        }
        logger.debug("AXStatusLabel for \(dockName, privacy: .public), type=\(badge.map { String(describing: CFGetTypeID($0)) } ?? "nil", privacy: .public), value=\(badgeText(from: badge) ?? "nil", privacy: .public)")
        return .value(badgeText(from: badge))
    }

    static func badgeText(from value: Any?) -> String? {
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private static func findElement(_ root: AXUIElement, titled title: String) -> AXUIElement? {
        var currentTitle: CFTypeRef?
        if AXUIElementCopyAttributeValue(root, kAXTitleAttribute as CFString, &currentTitle) == .success,
           currentTitle as? String == title { return root }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &children) == .success,
              let items = children as? [AXUIElement] else { return nil }
        return items.lazy.compactMap { findElement($0, titled: title) }.first
    }

}

public final class BadgePollingCoordinator: @unchecked Sendable {
    private let reader: (String) -> BadgeReadStatus
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var pollInFlight = false

    public init(
        queue: DispatchQueue = DispatchQueue(label: "blaine.unreadbadge.badge-polling"),
        reader: @escaping (String) -> BadgeReadStatus
    ) {
        self.queue = queue
        self.reader = reader
    }

    @discardableResult
    public func poll(
        dockNames: [String],
        completion: @escaping ([BadgeReadStatus]) -> Void
    ) -> Bool {
        lock.lock()
        guard !pollInFlight else {
            lock.unlock()
            return false
        }
        pollInFlight = true
        lock.unlock()

        queue.async { [weak self] in
            guard let self else { return }
            let statuses = dockNames.map(reader)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                lock.lock()
                pollInFlight = false
                lock.unlock()
                completion(statuses)
            }
        }
        return true
    }
}

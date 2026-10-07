import Foundation

public struct RunningApplicationOption: Hashable, Sendable {
    public let displayName: String
    public let bundleIdentifier: String?
    public let bundlePath: String?

    public init(displayName: String, bundleIdentifier: String?, bundlePath: String?) {
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.bundlePath = bundlePath
    }
}

public enum ApplicationPickerOptions {
    public static func runningOptions(
        from candidates: [RunningApplicationOption],
        currentBundleIdentifier: String?
    ) -> [RunningApplicationOption] {
        let withoutCurrentApp = candidates.filter { $0.bundleIdentifier != currentBundleIdentifier }
        let uniqueOptions = Dictionary(grouping: withoutCurrentApp, by: { option in
            option.bundleIdentifier ?? option.bundlePath ?? option.displayName
        }).compactMap { $0.value.first }

        return uniqueOptions.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }
}

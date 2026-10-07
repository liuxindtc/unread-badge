import Foundation

public enum InstanceLaunchAction: Equatable, Sendable {
    case launch
    case forwardSettingsRequest
}

public enum InstanceLaunchPolicy {
    public static func action(existingProcessIDs: [Int32], currentProcessID: Int32) -> InstanceLaunchAction {
        existingProcessIDs.contains { $0 != currentProcessID } ? .forwardSettingsRequest : .launch
    }

    public static func shouldShowSettingsOnReopen(hasVisibleWindows: Bool) -> Bool {
        true
    }
}

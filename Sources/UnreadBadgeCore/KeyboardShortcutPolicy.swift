import Foundation

public enum KeyboardShortcutPolicy {
    public static func isSettingsShortcut(commandPressed: Bool, keyCode: UInt16) -> Bool {
        commandPressed && keyCode == 43
    }
}

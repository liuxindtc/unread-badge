import Foundation

public enum BubbleForegroundStyle: Equatable, Sendable {
    case dark
    case light
}

public enum BubbleForegroundPolicy {
    public static func style(for backgroundHex: String) -> BubbleForegroundStyle {
        let normalized = backgroundHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(normalized, radix: 16) ?? 0
        let red = Double((value >> 16) & 255) / 255
        let green = Double((value >> 8) & 255) / 255
        let blue = Double(value & 255) / 255
        let luminance = red * 0.2126 + green * 0.7152 + blue * 0.0722
        return luminance >= 0.5 ? .dark : .light
    }
}

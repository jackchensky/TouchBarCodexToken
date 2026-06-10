import AppKit

struct HUDAppearance: Equatable {
    enum ColorChoice: String, CaseIterable {
        case black
        case graphite
        case blue
        case green
        case purple

        var title: String {
            switch self {
            case .black:
                return "深黑"
            case .graphite:
                return "石墨"
            case .blue:
                return "深蓝"
            case .green:
                return "深绿"
            case .purple:
                return "紫色"
            }
        }

        var color: NSColor {
            switch self {
            case .black:
                return NSColor(calibratedWhite: 0.04, alpha: 1)
            case .graphite:
                return NSColor(calibratedWhite: 0.18, alpha: 1)
            case .blue:
                return NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.22, alpha: 1)
            case .green:
                return NSColor(calibratedRed: 0.04, green: 0.16, blue: 0.10, alpha: 1)
            case .purple:
                return NSColor(calibratedRed: 0.15, green: 0.08, blue: 0.22, alpha: 1)
            }
        }
    }

    static let opacityChoices: [Double] = [0.60, 0.75, 0.86, 1.0]

    private enum DefaultsKey {
        static let color = "hud.color"
        static let opacity = "hud.opacity"
    }

    var colorChoice: ColorChoice
    var opacity: Double

    var backgroundColor: NSColor {
        colorChoice.color.withAlphaComponent(opacity)
    }

    static func load() -> HUDAppearance {
        let defaults = UserDefaults.standard
        let colorName = defaults.string(forKey: DefaultsKey.color) ?? ColorChoice.black.rawValue
        let color = ColorChoice(rawValue: colorName) ?? .black
        let storedOpacity = defaults.object(forKey: DefaultsKey.opacity) as? Double
        let opacity = storedOpacity ?? 0.86

        return HUDAppearance(
            colorChoice: color,
            opacity: max(0.45, min(1.0, opacity))
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(colorChoice.rawValue, forKey: DefaultsKey.color)
        defaults.set(opacity, forKey: DefaultsKey.opacity)
    }
}

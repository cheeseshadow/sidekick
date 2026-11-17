import Foundation

public struct SidekickConfig: Sendable, Equatable {
    public static let defaultHoverOpacity = 0.15
    public static let defaultHoverFadeBackDelay: Duration = .milliseconds(100)
    public static let defaultMaxVisibleTasks = 12
    public static let defaultWindowWidth = 300.0
    public static let defaultFontSize = 13.0
    public static let defaultBackgroundTintOpacity = 0.6

    public var tasksFilePath: String
    public var hoverOpacity: Double
    public var hoverFadeBackDelay: Duration
    public var maxVisibleTasks: Int
    public var windowWidth: Double
    public var fontSize: Double
    public var accentColor: HexColor?
    public var backgroundTintLight: HexColor?
    public var backgroundTintDark: HexColor?
    public var backgroundTintOpacity: Double

    /// `displayPath` names the config file in error messages.
    public static func parse(_ data: Data, displayPath: String) throws(ConfigError) -> SidekickConfig {
        let file: ConfigFile
        do {
            file = try JSONDecoder().decode(ConfigFile.self, from: data)
        } catch {
            throw ConfigError(message: "Invalid config file at \(displayPath)")
        }

        let fadeBackDelay = file.hoverFadeBackDelayMs.map { Duration.milliseconds($0) } ?? defaultHoverFadeBackDelay
        guard fadeBackDelay >= .zero else {
            throw ConfigError(message: "hover_fade_back_delay_ms must be 0 or more in \(displayPath)")
        }
        let maxVisibleTasks = file.maxVisibleTasks ?? defaultMaxVisibleTasks
        guard maxVisibleTasks >= 1 else {
            throw ConfigError(message: "max_visible_tasks must be 1 or more in \(displayPath)")
        }

        return SidekickConfig(
            tasksFilePath: (file.tasksFile as NSString).expandingTildeInPath,
            hoverOpacity: try fraction(file.hoverOpacityPercent, key: "hover_opacity_percent", displayPath: displayPath)
                ?? defaultHoverOpacity,
            hoverFadeBackDelay: fadeBackDelay,
            maxVisibleTasks: maxVisibleTasks,
            windowWidth: try positive(file.windowWidth, key: "window_width", displayPath: displayPath)
                ?? defaultWindowWidth,
            fontSize: try positive(file.fontSize, key: "font_size", displayPath: displayPath) ?? defaultFontSize,
            accentColor: try color(file.accentColor, key: "accent_color", displayPath: displayPath),
            backgroundTintLight: try color(
                file.backgroundTintLight,
                key: "background_tint_light",
                displayPath: displayPath
            ),
            backgroundTintDark: try color(file.backgroundTintDark, key: "background_tint_dark", displayPath: displayPath),
            backgroundTintOpacity: try fraction(
                file.backgroundTintOpacityPercent,
                key: "background_tint_opacity_percent",
                displayPath: displayPath
            ) ?? defaultBackgroundTintOpacity
        )
    }

    private static func fraction(_ percent: Double?, key: String, displayPath: String) throws(ConfigError) -> Double? {
        guard let percent else { return nil }
        guard (0...100).contains(percent) else {
            throw ConfigError(message: "\(key) must be from 0 to 100 in \(displayPath)")
        }

        return percent / 100
    }

    private static func positive(_ value: Double?, key: String, displayPath: String) throws(ConfigError) -> Double? {
        guard let value else { return nil }
        guard value > 0 else {
            throw ConfigError(message: "\(key) must be more than 0 in \(displayPath)")
        }

        return value
    }

    private static func color(_ value: String?, key: String, displayPath: String) throws(ConfigError) -> HexColor? {
        guard let value else { return nil }
        guard let color = HexColor(hex: value) else {
            throw ConfigError(message: "\(key) must be a hex color like #3366CC in \(displayPath)")
        }

        return color
    }
}

public struct ConfigError: Error, Equatable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public struct HexColor: Sendable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double

    /// Reads `#RRGGBB`.
    public init?(hex: String) {
        let digits = hex.dropFirst()
        guard hex.first == "#", digits.count == 6, digits.allSatisfy(\.isHexDigit),
              let value = UInt32(digits, radix: 16)
        else { return nil }

        red = Double((value >> 16) & 0xFF) / 255
        green = Double((value >> 8) & 0xFF) / 255
        blue = Double(value & 0xFF) / 255
    }
}

private struct ConfigFile: Decodable {
    let tasksFile: String
    let hoverOpacityPercent: Double?
    let hoverFadeBackDelayMs: Int?
    let maxVisibleTasks: Int?
    let windowWidth: Double?
    let fontSize: Double?
    let accentColor: String?
    let backgroundTintLight: String?
    let backgroundTintDark: String?
    let backgroundTintOpacityPercent: Double?

    enum CodingKeys: String, CodingKey {
        case tasksFile = "tasks_file"
        case hoverOpacityPercent = "hover_opacity_percent"
        case hoverFadeBackDelayMs = "hover_fade_back_delay_ms"
        case maxVisibleTasks = "max_visible_tasks"
        case windowWidth = "window_width"
        case fontSize = "font_size"
        case accentColor = "accent_color"
        case backgroundTintLight = "background_tint_light"
        case backgroundTintDark = "background_tint_dark"
        case backgroundTintOpacityPercent = "background_tint_opacity_percent"
    }
}

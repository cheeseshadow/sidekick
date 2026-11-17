import AppKit
import SidekickCore
import SwiftUI

enum Metrics {
    static let cornerRadius: CGFloat = 14
    static let cardInset: CGFloat = 6
    static let cardCornerRadius: CGFloat = 9
    static let cardHorizontalPadding: CGFloat = 10
    static let cardVerticalPadding: CGFloat = 10
    static let rowSpacing: CGFloat = 8
    static let groupSpacing: CGFloat = 10
    static let listVerticalPadding: CGFloat = 12
    static let lineSpacing: CGFloat = 2
    static let markerSpacing: CGFloat = 9

    /// Planned tasks line up with the tasks in the card.
    static var listLeadingPadding: CGFloat { cardInset + cardHorizontalPadding }
}

/// Sizes that follow the configured font size. The base values are drawn for the default font size.
struct Typography: Equatable {
    var fontSize: CGFloat

    private var scale: CGFloat { fontSize / CGFloat(SidekickConfig.defaultFontSize) }

    var footerSize: CGFloat { 11.5 * scale }
    var markerWidth: CGFloat { 12 * scale }
    var inProgressDotSize: CGFloat { 7 * scale }
    var plannedRingSize: CGFloat { 8 * scale }
    var completionDotSize: CGFloat { 12 * scale }
    var checkmarkSize: CGSize { CGSize(width: 6 * scale, height: 4.5 * scale) }

    /// The footer lines up with the task text.
    var textIndent: CGFloat { markerWidth + Metrics.markerSpacing }

    func font(weight: NSFont.Weight) -> NSFont {
        .systemFont(ofSize: fontSize, weight: weight)
    }
}

struct Palette: Equatable {
    var accent: Color
    var backgroundTintLight: Color?
    var backgroundTintDark: Color?
    var backgroundTintOpacity: Double

    static let system = Palette(
        accent: .accentColor,
        backgroundTintLight: nil,
        backgroundTintDark: nil,
        backgroundTintOpacity: SidekickConfig.defaultBackgroundTintOpacity
    )
}

extension Palette {
    init(config: SidekickConfig) {
        self.init(
            accent: config.accentColor.map(Color.init(hex:)) ?? .accentColor,
            backgroundTintLight: config.backgroundTintLight.map(Color.init(hex:)),
            backgroundTintDark: config.backgroundTintDark.map(Color.init(hex:)),
            backgroundTintOpacity: config.backgroundTintOpacity
        )
    }
}

extension EnvironmentValues {
    @Entry var palette: Palette = .system
    @Entry var typography = Typography(fontSize: CGFloat(SidekickConfig.defaultFontSize))
}

private extension Color {
    init(hex: HexColor) {
        self.init(.sRGB, red: hex.red, green: hex.green, blue: hex.blue)
    }
}

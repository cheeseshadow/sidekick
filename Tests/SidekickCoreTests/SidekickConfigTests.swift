import Foundation
import SidekickCore
import Testing

private func parse(_ json: String) throws(ConfigError) -> SidekickConfig {
    try SidekickConfig.parse(Data(json.utf8), displayPath: "config.json")
}

@Test func missingOptionalKeysUseTheDefaults() throws {
    let config = try parse(#"{"tasks_file": "~/tasks.md"}"#)

    #expect(config.tasksFilePath == (NSHomeDirectory() as NSString).appendingPathComponent("tasks.md"))
    #expect(config.hoverOpacity == SidekickConfig.defaultHoverOpacity)
    #expect(config.hoverFadeBackDelay == SidekickConfig.defaultHoverFadeBackDelay)
    #expect(config.maxVisibleTasks == SidekickConfig.defaultMaxVisibleTasks)
    #expect(config.windowWidth == SidekickConfig.defaultWindowWidth)
    #expect(config.fontSize == SidekickConfig.defaultFontSize)
    #expect(config.accentColor == nil)
    #expect(config.backgroundTintLight == nil)
    #expect(config.backgroundTintDark == nil)
    #expect(config.backgroundTintOpacity == SidekickConfig.defaultBackgroundTintOpacity)
}

@Test func readsEveryKey() throws {
    let config = try parse("""
    {
      "tasks_file": "/tmp/tasks.md",
      "hover_opacity_percent": 40,
      "hover_fade_back_delay_ms": 250,
      "max_visible_tasks": 5,
      "window_width": 360,
      "font_size": 15,
      "accent_color": "#3366CC",
      "background_tint_light": "#FFFFFF",
      "background_tint_dark": "#000000",
      "background_tint_opacity_percent": 30
    }
    """)

    #expect(config.tasksFilePath == "/tmp/tasks.md")
    #expect(config.hoverOpacity == 0.4)
    #expect(config.hoverFadeBackDelay == .milliseconds(250))
    #expect(config.maxVisibleTasks == 5)
    #expect(config.windowWidth == 360)
    #expect(config.fontSize == 15)
    #expect(config.accentColor == HexColor(hex: "#3366CC"))
    #expect(config.backgroundTintLight == HexColor(hex: "#FFFFFF"))
    #expect(config.backgroundTintDark == HexColor(hex: "#000000"))
    #expect(config.backgroundTintOpacity == 0.3)
}

@Test(arguments: [
    (#"{}"#, "Invalid config file at config.json"),
    (#"{"tasks_file": "t", "hover_opacity_percent": 101}"#, "hover_opacity_percent must be from 0 to 100 in config.json"),
    (#"{"tasks_file": "t", "hover_fade_back_delay_ms": -1}"#, "hover_fade_back_delay_ms must be 0 or more in config.json"),
    (#"{"tasks_file": "t", "max_visible_tasks": 0}"#, "max_visible_tasks must be 1 or more in config.json"),
    (#"{"tasks_file": "t", "window_width": 0}"#, "window_width must be more than 0 in config.json"),
    (#"{"tasks_file": "t", "font_size": -2}"#, "font_size must be more than 0 in config.json"),
    (#"{"tasks_file": "t", "accent_color": "blue"}"#, "accent_color must be a hex color like #3366CC in config.json"),
    (
        #"{"tasks_file": "t", "background_tint_opacity_percent": -5}"#,
        "background_tint_opacity_percent must be from 0 to 100 in config.json"
    ),
])
func invalidConfigNamesTheProblem(json: String, message: String) {
    #expect(throws: ConfigError(message: message)) { try parse(json) }
}

@Test func readsHexColors() throws {
    let color = try #require(HexColor(hex: "#ff8000"))

    #expect(color.red == 1)
    #expect(color.green == 128.0 / 255)
    #expect(color.blue == 0)
}

@Test(arguments: ["3366CC", "#3366C", "#3366CCD", "#3366CG", "#+12345", "#-00000", ""])
func rejectsMalformedHexColors(hex: String) {
    #expect(HexColor(hex: hex) == nil)
}

import Foundation
import SidekickCore

enum ConfigLoader {
    static let configURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".config/sidekick/config.json")

    static func load() -> Result<SidekickConfig, ConfigError> {
        let shownPath = displayPath(configURL)
        guard let data = try? Data(contentsOf: configURL) else {
            return .failure(ConfigError(message: "No config file at \(shownPath)"))
        }

        return Result { () throws(ConfigError) in try SidekickConfig.parse(data, displayPath: shownPath) }
    }

    static func displayPath(_ url: URL) -> String {
        (url.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
    }
}

import Foundation
import SidekickCore

enum WindowContent: Equatable, Sendable {
    case tasks(TaskList)
    case message(String)
}

/// Polls the config file and the tasks file. Many editors save by writing a new file in place of
/// the old one, which a watcher on the open file handle would miss.
actor FileWatcher {
    struct Update: Sendable {
        var config: Result<SidekickConfig, ConfigError>?
        var tasks: WindowContent?
    }

    private var config: Result<SidekickConfig, ConfigError>?
    private var configStamp: FileStamp?
    private var tasksStamp: FileStamp?

    /// Returns only what changed since the previous check, or everything if `force` is set.
    func check(force: Bool) -> Update {
        var update = Update()
        let newConfigStamp = FileStamp.of(ConfigLoader.configURL)
        let configChanged = force || newConfigStamp != configStamp
        if configChanged {
            configStamp = newConfigStamp
            config = ConfigLoader.load()
            update.config = config
        }
        guard case .success(let config) = config else { return update }

        let url = URL(filePath: config.tasksFilePath)
        let newTasksStamp = FileStamp.of(url)
        guard configChanged || newTasksStamp != tasksStamp else { return update }

        tasksStamp = newTasksStamp
        update.tasks = Self.readTasks(at: url, exists: newTasksStamp != nil)
        return update
    }

    private static func readTasks(at url: URL, exists: Bool) -> WindowContent {
        let shownPath = ConfigLoader.displayPath(url)
        guard exists else {
            return .message("No tasks file at \(shownPath)")
        }
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            return .message("Can't read the tasks file at \(shownPath)")
        }

        return .tasks(TaskParser.parse(markdown))
    }
}

private struct FileStamp: Equatable {
    let modified: Date?
    let size: Int?
    let fileNumber: Int?

    static func of(_ url: URL) -> FileStamp? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false)) else {
            return nil
        }

        return FileStamp(
            modified: attributes[.modificationDate] as? Date,
            size: (attributes[.size] as? NSNumber)?.intValue,
            fileNumber: (attributes[.systemFileNumber] as? NSNumber)?.intValue
        )
    }
}

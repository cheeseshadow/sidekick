import AppKit
import Observation
import SidekickCore
import SwiftUI

@MainActor
@Observable
final class TaskStore {
    static let completionHold: Duration = .milliseconds(550)
    static let completionFadeOut: Double = 0.25
    private static let pollInterval: Duration = .milliseconds(500)

    private(set) var content: WindowContent = .message("")
    private(set) var hoverOpacity = SidekickConfig.defaultHoverOpacity
    private(set) var hoverFadeBackDelay = SidekickConfig.defaultHoverFadeBackDelay
    private(set) var maxVisibleTasks = SidekickConfig.defaultMaxVisibleTasks
    private(set) var windowWidth = CGFloat(SidekickConfig.defaultWindowWidth)
    private(set) var fontSize = CGFloat(SidekickConfig.defaultFontSize)
    private(set) var palette = Palette.system
    private(set) var tasksFileURL: URL?

    /// Done tasks still on screen while their completion animation plays, with the group they were shown in.
    private var completing: [String: TaskStatus] = [:]

    @ObservationIgnored private let watcher = FileWatcher()
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    func start() {
        pollTask = Task { [weak self, watcher] in
            var force = true
            while !Task.isCancelled {
                let update = await watcher.check(force: force)
                force = false
                guard self?.receive(update) != nil else { return }

                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    var display: TaskDisplay? {
        guard case .tasks(let list) = content else { return nil }

        return TaskDisplay(list: list, completing: completing, maxVisibleTasks: maxVisibleTasks)
    }

    private func receive(_ update: FileWatcher.Update) {
        switch update.config {
        case .failure(let error):
            tasksFileURL = nil
            show(.message(error.message))
        case .success(let config):
            hoverOpacity = config.hoverOpacity
            hoverFadeBackDelay = config.hoverFadeBackDelay
            maxVisibleTasks = config.maxVisibleTasks
            windowWidth = CGFloat(config.windowWidth)
            fontSize = CGFloat(config.fontSize)
            palette = Palette(config: config)
            tasksFileURL = URL(filePath: config.tasksFilePath)
        case nil:
            break
        }

        switch update.tasks {
        case .tasks(let list):
            apply(list)
        case .message(let text):
            show(.message(text))
        case nil:
            break
        }
    }

    private func show(_ message: WindowContent) {
        guard content != message else { return }

        completing = [:]
        withAnimation(.easeInOut(duration: 0.2)) {
            content = message
        }
    }

    private func apply(_ parsed: TaskList) {
        let previous: TaskList? = if case .tasks(let list) = content { list } else { nil }
        let list = previous.map { parsed.carryingIdentity(from: $0) } ?? parsed
        guard content != .tasks(list) else { return }

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let newlyCompleted = reduceMotion ? [:] : previous.map { Self.newlyCompleted(from: $0, to: list) } ?? [:]
        let doneIDs = Set(list.tasks.filter { $0.status == .done }.map(\.id))

        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0)) {
            completing = completing
                .filter { doneIDs.contains($0.key) }
                .merging(newlyCompleted) { current, _ in current }
            content = .tasks(list)
        }

        for id in newlyCompleted.keys {
            Task { [weak self] in
                try? await Task.sleep(for: Self.completionHold)
                withAnimation(.easeOut(duration: Self.completionFadeOut)) {
                    _ = self?.completing.removeValue(forKey: id)
                }
            }
        }
    }

    private static func newlyCompleted(from previous: TaskList, to current: TaskList) -> [String: TaskStatus] {
        let shown = Dictionary(
            previous.tasks.filter { $0.status != .done }.map { ($0.id, $0.status) },
            uniquingKeysWith: { first, _ in first }
        )
        var completed: [String: TaskStatus] = [:]
        for task in current.tasks where task.status == .done {
            if let shownStatus = shown[task.id] {
                completed[task.id] = shownStatus
            }
        }

        return completed
    }
}

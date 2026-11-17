public struct TaskRow: Identifiable, Sendable, Equatable {
    public let id: String
    public let text: String
    public let isCompleting: Bool
}

/// What the window shows for a task list.
public struct TaskDisplay: Sendable, Equatable {
    public let inProgress: [TaskRow]
    public let planned: [TaskRow]
    public let hiddenCount: Int
    public let doneCount: Int
    public let isEmpty: Bool

    /// `completing` holds done tasks that stay on screen while their completion animation plays,
    /// with the status they were shown with before.
    public init(list: TaskList, completing: [String: TaskStatus], maxVisibleTasks: Int) {
        let inProgress = Self.rows(in: list, shownAs: .inProgress, completing: completing)
        let planned = Self.rows(in: list, shownAs: .planned, completing: completing)
        let visibleInProgress = inProgress.prefix(maxVisibleTasks)
        let visiblePlanned = planned.prefix(maxVisibleTasks - visibleInProgress.count)

        self.inProgress = Array(visibleInProgress)
        self.planned = Array(visiblePlanned)
        hiddenCount = inProgress.count + planned.count - visibleInProgress.count - visiblePlanned.count
        doneCount = list.tasks.filter { $0.status == .done && completing[$0.id] == nil }.count
        isEmpty = list.tasks.isEmpty
    }

    public var footer: String? {
        let parts = [
            hiddenCount > 0 ? "\(hiddenCount) more" : nil,
            doneCount > 0 ? "\(doneCount) done" : nil,
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func rows(in list: TaskList, shownAs group: TaskStatus, completing: [String: TaskStatus]) -> [TaskRow] {
        list.tasks
            .filter { $0.status == group || completing[$0.id] == group }
            .map { TaskRow(id: $0.id, text: $0.text, isCompleting: $0.status == .done) }
    }
}

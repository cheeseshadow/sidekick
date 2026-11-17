public enum TaskStatus: Sendable, Equatable {
    case planned
    case inProgress
    case done
}

public struct TaskItem: Identifiable, Sendable, Equatable {
    public var id: String
    public var text: String
    public var status: TaskStatus

    public init(id: String, text: String, status: TaskStatus) {
        self.id = id
        self.text = text
        self.status = status
    }
}

public struct TaskList: Sendable, Equatable {
    public var tasks: [TaskItem]

    public init(tasks: [TaskItem]) {
        self.tasks = tasks
    }

    /// Ids come from the task text, so an edited task would look like a removed task and a new one.
    /// This gives an edited task its previous id when it sits at the same position with the same status.
    public func carryingIdentity(from previous: TaskList) -> TaskList {
        let currentIDs = Set(tasks.map(\.id))
        let previousIDs = Set(previous.tasks.map(\.id))
        var result = self
        for index in result.tasks.indices
        where !previousIDs.contains(result.tasks[index].id) && index < previous.tasks.count {
            let candidate = previous.tasks[index]
            if !currentIDs.contains(candidate.id) && candidate.status == result.tasks[index].status {
                result.tasks[index].id = candidate.id
            }
        }

        return result
    }
}

public enum TaskParser {
    public static func parse(_ markdown: String) -> TaskList {
        var tasks: [TaskItem] = []
        var seenTexts: [String: Int] = [:]

        for line in markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            guard let (status, text) = parseLine(String(line)) else { continue }

            let occurrence = seenTexts[text, default: 0]
            seenTexts[text] = occurrence + 1
            let id = occurrence == 0 ? text : "\(text)\u{1F}\(occurrence)"
            tasks.append(TaskItem(id: id, text: text, status: status))
        }

        return TaskList(tasks: tasks)
    }

    /// Only top-level task lines count. Indented task lines are steps that the file can hold
    /// but the window does not show.
    private static func parseLine(_ line: String) -> (TaskStatus, String)? {
        let pattern = /^ ?[-*] \[(?<mark>[ xX\/])\] +(?<text>.*?)\s*$/
        guard let match = line.wholeMatch(of: pattern), !match.text.isEmpty else { return nil }

        let status: TaskStatus = switch match.mark {
        case " ": .planned
        case "/": .inProgress
        default: .done
        }

        return (status, String(match.text))
    }
}

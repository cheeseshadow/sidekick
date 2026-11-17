import SidekickCore
import Testing

@Test func readsTasksAndIgnoresEverythingElse() {
    let markdown = """
    # Today

    Some note about the day.

    ## Project
    - [/] Review the pull request
    - [ ] Reply to the email
    * [X] Book the meeting room
    - [] Malformed line
    -[ ] Also malformed
    - [ ]
    """

    let list = TaskParser.parse(markdown)

    #expect(list.tasks.map(\.text) == ["Review the pull request", "Reply to the email", "Book the meeting room"])
    #expect(list.tasks.map(\.status) == [.inProgress, .planned, .done])
}

@Test func taskLinesIndentedByTwoOrMoreSpacesAreIgnored() {
    let markdown = "- [/] Build the first version\n  - [x] Window and config\n\t- [ ] Animations\n - [ ] Write the readme"

    let list = TaskParser.parse(markdown)

    #expect(list.tasks.map(\.text) == ["Build the first version", "Write the readme"])
    #expect(list.tasks.map(\.status) == [.inProgress, .planned])
}

@Test func readsWindowsLineEndings() {
    let list = TaskParser.parse("- [ ] First\r\n- [ ] Second\r\n")

    #expect(list.tasks.map(\.text) == ["First", "Second"])
}

@Test func tasksWithTheSameTextGetDistinctIDs() {
    let list = TaskParser.parse("- [ ] Check CI\n- [ ] Check CI")

    #expect(Set(list.tasks.map(\.id)).count == 2)
}

@Test func editedTaskKeepsItsIdentity() {
    let before = TaskParser.parse("- [ ] Reply to the email\n- [ ] Write the readme")
    let after = TaskParser.parse("- [ ] Reply to the email about the demo\n- [ ] Write the readme")

    let carried = after.carryingIdentity(from: before)

    #expect(carried.tasks.map(\.id) == before.tasks.map(\.id))
    #expect(carried.tasks[0].text == "Reply to the email about the demo")
}

@Test func movedTaskKeepsItsIdentity() {
    let before = TaskParser.parse("- [ ] Reply to the email\n- [ ] Write the readme")
    let after = TaskParser.parse("- [ ] Write the readme\n- [ ] Reply to the email")

    let carried = after.carryingIdentity(from: before)

    #expect(carried.tasks.map(\.id) == ["Write the readme", "Reply to the email"])
}

@Test func insertedTaskDoesNotTakeAnotherTasksIdentity() {
    let before = TaskParser.parse("- [ ] Reply to the email\n- [ ] Write the readme")
    let after = TaskParser.parse("- [ ] New task\n- [ ] Reply to the email\n- [ ] Write the readme")

    let carried = after.carryingIdentity(from: before)

    #expect(carried.tasks.map(\.id) == ["New task", "Reply to the email", "Write the readme"])
}

@Test func taskThatChangesTextAndStatusIsANewTask() {
    let before = TaskParser.parse("- [ ] Reply to the email")
    let after = TaskParser.parse("- [/] Reply to the email today")

    let carried = after.carryingIdentity(from: before)

    #expect(carried.tasks.map(\.id) == ["Reply to the email today"])
}

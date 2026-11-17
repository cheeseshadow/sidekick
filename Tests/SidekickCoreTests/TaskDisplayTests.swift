import SidekickCore
import Testing

@Test func inProgressTasksTakeTheVisibleSlotsFirst() {
    let list = TaskParser.parse("- [ ] One\n- [ ] Two\n- [/] Three\n- [/] Four")

    let display = TaskDisplay(list: list, completing: [:], maxVisibleTasks: 3)

    #expect(display.inProgress.map(\.text) == ["Three", "Four"])
    #expect(display.planned.map(\.text) == ["One"])
    #expect(display.hiddenCount == 1)
}

@Test func inProgressTasksPastTheLimitAreHidden() {
    let list = TaskParser.parse("- [/] One\n- [/] Two\n- [ ] Three")

    let display = TaskDisplay(list: list, completing: [:], maxVisibleTasks: 1)

    #expect(display.inProgress.map(\.text) == ["One"])
    #expect(display.planned.isEmpty)
    #expect(display.hiddenCount == 2)
}

@Test func completingTaskStaysInItsGroupAndIsNotCountedAsDone() {
    let list = TaskParser.parse("- [x] One\n- [ ] Two\n- [x] Three")

    let display = TaskDisplay(list: list, completing: ["One": .inProgress], maxVisibleTasks: 12)

    #expect(display.inProgress.map(\.text) == ["One"])
    #expect(display.inProgress.map(\.isCompleting) == [true])
    #expect(display.planned.map(\.text) == ["Two"])
    #expect(display.doneCount == 1)
}

@Test func listWithOnlyDoneTasksShowsOnlyTheFooter() {
    let display = TaskDisplay(list: TaskParser.parse("- [x] One\n- [x] Two"), completing: [:], maxVisibleTasks: 12)

    #expect(display.inProgress.isEmpty)
    #expect(display.planned.isEmpty)
    #expect(!display.isEmpty)
    #expect(display.footer == "2 done")
}

@Test func emptyListHasNoFooter() {
    let display = TaskDisplay(list: TaskParser.parse("# Nothing yet"), completing: [:], maxVisibleTasks: 12)

    #expect(display.isEmpty)
    #expect(display.footer == nil)
}

@Test func footerJoinsHiddenAndDoneCounts() {
    let list = TaskParser.parse("- [ ] One\n- [ ] Two\n- [x] Three")

    let display = TaskDisplay(list: list, completing: [:], maxVisibleTasks: 1)

    #expect(display.footer == "1 more · 1 done")
}

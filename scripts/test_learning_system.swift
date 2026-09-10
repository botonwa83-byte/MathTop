import Foundation

@main
struct LearningSystemRegressionTests {
    static func main() throws {
        try testStorePersistsSessionsEventsAndStreaks()
        try testGrowthSummaryUsesRecentCapabilityEvents()
        try testEmptyGrowthSummaryIsActionable()
        try testDailyPlanBuildsCompleteLearningLoop()
        try testDailyPlanPrioritizesDueReview()
        print("PASS: learning system regression tests")
    }

    private static func testStorePersistsSessionsEventsAndStreaks() throws {
        let suiteName = "MathTopLearningSystemTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create isolated defaults")
        }
        defaults.removePersistentDomain(forName: suiteName)

        var now = fixedDate(2026, 9, 10)
        let calendar = fixedCalendar()
        let activity = LearningActivity(
            id: "act-test-transfer",
            title: "测试迁移",
            mode: .transfer,
            prompt: "写出数量关系",
            lessonID: "p-percent",
            stage: .primary,
            capabilities: [.modeling],
            minutes: 4,
            successCriteria: "写出关系式",
            feedback: "完成建模"
        )
        let session = StudySession(id: "study-20260910-小学", date: now, stage: .primary, activities: [activity], completedActivityIDs: [])
        let store = LearningStore(defaults: defaults, now: { now }, calendar: calendar)

        precondition(store.activityEvents.isEmpty, "Fresh store should not have activity events")
        precondition(store.studySessions.isEmpty, "Fresh store should not have study sessions")
        store.upsertStudySession(session)
        store.completeActivity(activity, in: session, score: 0.8, note: "先找变量")
        store.completeActivity(activity, in: session, score: 0.1, note: "重复打开不应重复计数")

        precondition(store.activityEvents.count == 1, "Completing an activity records one event")
        precondition(store.activityEvents[0].score == 0.8, "Event score should persist")
        precondition(store.activityEvents[0].capabilities == [.modeling], "Event capabilities should persist")
        precondition(store.studySessions.first?.isCompleted == true, "Session should be complete after its only activity")
        precondition(store.streak == 1, "First study day starts a streak")

        let reloaded = LearningStore(defaults: defaults, now: { now }, calendar: calendar)
        precondition(reloaded.activityEvents.count == 1, "Events should reload from defaults")
        precondition(reloaded.studySessions.first?.isCompleted == true, "Sessions should reload from defaults")
        precondition(reloaded.streak == 1, "Streak should reload from defaults")
        precondition(reloaded.session(on: now, stage: .primary, calendar: calendar)?.id == session.id, "Store should find today's session")

        now = fixedDate(2026, 9, 11)
        let nextActivity = LearningActivity(
            id: "act-test-reflect",
            title: "测试复盘",
            mode: .reflect,
            prompt: "选择错因",
            lessonID: nil,
            stage: .primary,
            capabilities: [.focusReflection],
            minutes: 2,
            successCriteria: "选出错因",
            feedback: "完成复盘"
        )
        let nextSession = StudySession(id: "study-20260911-小学", date: now, stage: .primary, activities: [nextActivity], completedActivityIDs: [])
        reloaded.completeActivity(nextActivity, in: nextSession)
        precondition(reloaded.streak == 2, "Consecutive days should increment streak")
        precondition(reloaded.reflectionCount == 1, "Reflection count should include reflect events")

        now = fixedDate(2026, 9, 14)
        let gapActivity = LearningActivity(
            id: "act-test-focus",
            title: "测试专注",
            mode: .focus,
            prompt: "专注练习",
            lessonID: nil,
            stage: .primary,
            capabilities: [.focusReflection],
            minutes: 3,
            successCriteria: "完成三分钟",
            feedback: "完成专注"
        )
        let gapSession = StudySession(id: "study-20260914-小学", date: now, stage: .primary, activities: [gapActivity], completedActivityIDs: [])
        reloaded.completeActivity(gapActivity, in: gapSession)
        precondition(reloaded.streak == 1, "A date gap resets streak to one")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func testGrowthSummaryUsesRecentCapabilityEvents() throws {
        let calendar = fixedCalendar()
        let now = fixedDate(2026, 9, 10)
        let oldDate = calendar.date(byAdding: .day, value: -40, to: now)!
        let lessons = [
            Lesson(id: "p-percent", title: "百分数", ability: "解决问题", subject: .math, stage: .primary, minutes: 8, summary: "折扣", questions: [], capabilities: [.modeling]),
            Lesson(id: "p-four", title: "四则运算", ability: "数与运算", subject: .math, stage: .primary, minutes: 8, summary: "计算", questions: [], capabilities: [.numberSense])
        ]
        let events = [
            LearningActivityEvent(id: UUID(), activityID: "transfer", sessionID: "s1", lessonID: "p-percent", mode: .transfer, capabilities: [.modeling], score: 1, note: nil, date: now),
            LearningActivityEvent(id: UUID(), activityID: "reflect", sessionID: "s1", lessonID: nil, mode: .reflect, capabilities: [.expression], score: 1, note: "讲清关系", date: now),
            LearningActivityEvent(id: UUID(), activityID: "old", sessionID: "s0", lessonID: "p-four", mode: .practice, capabilities: [.numberSense], score: 1, note: nil, date: oldDate)
        ]
        let attempts = [
            Attempt(id: UUID(), questionID: "q1", lessonID: "p-percent", correct: false, date: now)
        ]

        let snapshots = GrowthSummaryService.makeCapabilitySnapshots(events: events, attempts: attempts, lessons: lessons, now: now, calendar: calendar)
        precondition(snapshots.count == Capability.allCases.count, "Need one snapshot per capability")
        let modeling = snapshots.first { $0.capability == .modeling }!
        let numberSense = snapshots.first { $0.capability == .numberSense }!
        precondition(modeling.practiceCount == 2, "Modeling should count transfer plus related attempt")
        precondition(modeling.mastery > 0, "Recent transfer should increase modeling mastery")
        precondition(numberSense.practiceCount == 0, "Events older than 30 days should not affect current snapshots")
    }

    private static func testEmptyGrowthSummaryIsActionable() throws {
        let suiteName = "MathTopGrowthEmptyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = LearningStore(defaults: defaults, now: { fixedDate(2026, 9, 10) }, calendar: fixedCalendar())

        let summary = GrowthSummaryService.make(store: store, now: fixedDate(2026, 9, 10), calendar: fixedCalendar())
        precondition(summary.capabilitySnapshots.count == Capability.allCases.count, "Empty store still needs five capability snapshots")
        precondition(summary.nextStep == "先完成今日任务包，用一道题建立学习记录。", "Empty summary needs a concrete first action")
        precondition(summary.sevenDayActivityCounts.count == 7, "Growth summary needs seven trend points")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func testDailyPlanBuildsCompleteLearningLoop() throws {
        let suiteName = "MathTopDailyPlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let now = fixedDate(2026, 9, 10)
        let store = LearningStore(defaults: defaults, now: { now }, calendar: fixedCalendar())

        let plan = DailyPlanService.makePlan(stage: .primary, store: store, now: now, calendar: fixedCalendar())
        precondition(plan.session.activities.count == 4, "Daily plan should have understand, practice, transfer, and reflection")
        precondition(plan.session.activities.map(\.mode).contains(.understand), "Daily plan missing understand activity")
        precondition(plan.session.activities.map(\.mode).contains(.practice), "Daily plan missing practice activity")
        precondition(plan.session.activities.map(\.mode).contains(.transfer), "Daily plan missing transfer activity")
        precondition(plan.session.activities.map(\.mode).contains(.reflect), "Daily plan missing reflection activity")
        precondition((10...15).contains(plan.estimatedMinutes), "Daily plan should last 10-15 minutes")
        precondition(plan.primary.stage == .primary, "Primary plan should pick primary lesson")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func testDailyPlanPrioritizesDueReview() throws {
        let suiteName = "MathTopDueReviewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var now = fixedDate(2026, 9, 1)
        let calendar = fixedCalendar()
        let store = LearningStore(defaults: defaults, now: { now }, calendar: calendar)
        store.recordAttempt(questionID: "p-percent-1", lessonID: "p-percent", correct: false)

        now = fixedDate(2026, 9, 10)
        let plan = DailyPlanService.makePlan(stage: .primary, store: store, now: now, calendar: calendar)
        precondition(plan.primary.id == "p-percent", "Due incorrect attempts should drive the primary lesson")
        precondition(plan.dueReviewCount == 1, "Plan should expose due review count")
        precondition(plan.session.activities.contains { $0.capabilities.contains(.modeling) }, "Plan should include modeling work for p-percent")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func fixedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        return calendar
    }

    private static func fixedDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = fixedCalendar()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 9
        return components.date!
    }
}

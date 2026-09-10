import Foundation

struct DailyPlan {
    let session: StudySession
    let primary: Lesson
    let next: Lesson?
    let stage: Stage
    let dueReviewCount: Int
    let weakCapability: Capability?

    var estimatedMinutes: Int { session.estimatedMinutes }
}

enum DailyPlanService {
    static func makePlan(stage: Stage, store: LearningStore, now: Date = Date(), calendar: Calendar = .current) -> DailyPlan {
        makePlan(stage: stage, store: store, now: now, calendar: calendar, lessons: MathContent.lessons(for: stage), activities: MathContent.learningActivities)
    }

    static func makePlan(stage: Stage, store: LearningStore, now: Date = Date(), calendar: Calendar = .current, lessons: [Lesson], activities: [LearningActivity]) -> DailyPlan {
        if let existing = store.session(on: now, stage: stage, calendar: calendar), let primary = primaryLesson(for: existing, lessons: lessons, stage: stage) {
            return DailyPlan(session: existing, primary: primary, next: nextLesson(after: primary, in: lessons, store: store), stage: stage, dueReviewCount: dueAttempts(in: store, lessons: lessons, now: now, calendar: calendar).count, weakCapability: GrowthSummaryService.make(store: store, now: now, calendar: calendar).weakCapability?.capability)
        }

        let fallback = Lesson(id: "empty-\(stage.rawValue)", title: "准备你的第一课", ability: "基础能力", subject: .math, stage: stage, minutes: 5, summary: "题库正在准备，先从基础概念开始。", questions: [], capabilities: [.numberSense, .focusReflection])
        let candidateLessons = lessons.isEmpty ? [fallback] : lessons
        let due = dueAttempts(in: store, lessons: candidateLessons, now: now, calendar: calendar)
        let weakCapability = GrowthSummaryService.make(store: store, now: now, calendar: calendar).weakCapability?.capability
        let primary = lessonForDueAttempt(due.first, lessons: candidateLessons)
            ?? lessonForCapability(weakCapability, lessons: candidateLessons, store: store)
            ?? candidateLessons.first(where: { !store.completedLessonIDs.contains($0.id) })
            ?? candidateLessons[0]
        let transfer = transferActivity(for: primary, weakCapability: weakCapability, stage: stage, activities: activities)
        let session = StudySession(
            id: sessionID(for: stage, date: now, calendar: calendar),
            date: now,
            stage: stage,
            activities: [
                understandActivity(for: primary),
                practiceActivity(for: primary),
                transfer,
                reflectionActivity(for: primary)
            ],
            completedActivityIDs: []
        )
        return DailyPlan(session: session, primary: primary, next: nextLesson(after: primary, in: candidateLessons, store: store), stage: stage, dueReviewCount: due.count, weakCapability: weakCapability)
    }

    private static func dueAttempts(in store: LearningStore, lessons: [Lesson], now: Date, calendar: Calendar) -> [Attempt] {
        let lessonIDs = Set(lessons.map(\.id))
        return store.attempts.filter { lessonIDs.contains($0.lessonID) && ReviewScheduler.isDue($0, now: now, calendar: calendar) }
    }

    private static func lessonForDueAttempt(_ attempt: Attempt?, lessons: [Lesson]) -> Lesson? {
        guard let attempt else { return nil }
        return lessons.first { $0.id == attempt.lessonID }
    }

    private static func lessonForCapability(_ capability: Capability?, lessons: [Lesson], store: LearningStore) -> Lesson? {
        guard let capability else { return nil }
        return lessons.first { lesson in
            lesson.capabilities.contains(capability) && !store.completedLessonIDs.contains(lesson.id)
        } ?? lessons.first { $0.capabilities.contains(capability) }
    }

    private static func primaryLesson(for session: StudySession, lessons: [Lesson], stage: Stage) -> Lesson? {
        if let lessonID = session.activities.compactMap(\.lessonID).first {
            return lessons.first { $0.id == lessonID }
        }
        return lessons.first { $0.stage == stage }
    }

    private static func nextLesson(after lesson: Lesson, in lessons: [Lesson], store: LearningStore) -> Lesson? {
        if let nextIncomplete = lessons.first(where: { $0.id != lesson.id && !store.completedLessonIDs.contains($0.id) }) {
            return nextIncomplete
        }
        guard let index = lessons.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        let nextIndex = index + 1
        return nextIndex < lessons.count ? lessons[nextIndex] : nil
    }

    private static func understandActivity(for lesson: Lesson) -> LearningActivity {
        LearningActivity(id: "understand-\(lesson.id)", title: "看懂 \(lesson.title)", mode: .understand, prompt: lesson.summary, lessonID: lesson.id, stage: lesson.stage, capabilities: lesson.capabilities, minutes: 2, successCriteria: "能说出本课要解决的核心关系。", feedback: "先看懂目标，再进入练习。")
    }

    private static func practiceActivity(for lesson: Lesson) -> LearningActivity {
        let ids = Array(lesson.questions.prefix(3).map(\.id))
        return LearningActivity(id: "practice-\(lesson.id)", title: "练习 \(lesson.title)", mode: .practice, prompt: lesson.questions.isEmpty ? "用自己的话复述本课方法，再完成一道同类题。" : "完成 2 到 3 道题，答题后看解析。", lessonID: lesson.id, questionIDs: ids, stage: lesson.stage, capabilities: lesson.capabilities, minutes: 4, successCriteria: "完成练习并查看关键解析。", feedback: "练习记录会进入能力成长。")
    }

    private static func transferActivity(for lesson: Lesson, weakCapability: Capability?, stage: Stage, activities: [LearningActivity]) -> LearningActivity {
        let stageActivities = activities.filter { $0.stage == stage && $0.mode == .transfer }
        if let weakCapability, let match = stageActivities.first(where: { $0.capabilities.contains(weakCapability) }) {
            return match
        }
        if let match = stageActivities.first(where: { activity in
            activity.lessonID == lesson.id || !Set(activity.capabilities).isDisjoint(with: lesson.capabilities)
        }) {
            return match
        }
        return LearningActivity(id: "transfer-\(lesson.id)", title: "迁移 \(lesson.title)", mode: .transfer, prompt: "把 \(lesson.title) 放进一个生活情境，写出数量关系或判断依据。", lessonID: lesson.id, stage: stage, capabilities: lesson.capabilities, minutes: 4, successCriteria: "能说明情境、关系和结论。", feedback: "你完成了一次从知识点到真实问题的迁移。")
    }

    private static func reflectionActivity(for lesson: Lesson) -> LearningActivity {
        LearningActivity(id: "reflect-\(lesson.id)", title: "复盘 \(lesson.title)", mode: .reflect, prompt: "今天最卡的是审题、计算、表达还是验证？写下一句下次提醒。", lessonID: lesson.id, stage: lesson.stage, capabilities: [.expression, .focusReflection], minutes: 2, successCriteria: "能选出一个卡点并写出下次动作。", feedback: "复盘让下一次练习更有方向。", choices: ["审题", "计算", "表达", "验证"])
    }

    private static func sessionID(for stage: Stage, date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "study-%04d%02d%02d-%@", components.year ?? 0, components.month ?? 0, components.day ?? 0, stage.rawValue)
    }
}

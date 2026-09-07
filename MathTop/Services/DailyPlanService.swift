import Foundation

struct DailyPlan {
    let primary: Lesson
    let next: Lesson?
    let stage: Stage
}

enum DailyPlanService {
    static func makePlan(stage: Stage, store: LearningStore) -> DailyPlan {
        let math = MathContent.lessons(for: stage)
        let nextMath = math.first(where: { !store.completedLessonIDs.contains($0.id) }) ?? math[0]
        let nextMathIndex = math.firstIndex(where: { $0.id == nextMath.id }).map { $0 + 1 } ?? 0
        let next = nextMathIndex < math.count ? math[nextMathIndex] : nil
        return DailyPlan(primary: nextMath, next: next, stage: stage)
    }
}

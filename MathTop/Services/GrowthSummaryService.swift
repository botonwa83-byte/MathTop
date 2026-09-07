import Foundation

struct GrowthSummary {
    let completed: Int
    let total: Int
    let attempts: Int
    let incorrect: Int
    var mastery: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}

enum GrowthSummaryService {
    static func make(store: LearningStore) -> GrowthSummary { GrowthSummary(completed: store.completedLessonIDs.count, total: MathContent.lessons.count, attempts: store.attempts.count, incorrect: store.incorrectAttempts.count) }
}

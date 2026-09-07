import Foundation

struct CurriculumModuleSummary: Identifiable {
    let id: String
    let stage: Stage
    let module: String
    let lessonCount: Int
    let questionCount: Int
}

enum CurriculumAudit {
    static func summaries() -> [CurriculumModuleSummary] {
        MathContent.lessons
            .reduce(into: [String: (Stage, String, Int, Int)]()) { result, lesson in
                let key = "\(lesson.stage.rawValue)-\(lesson.ability)"
                let current = result[key] ?? (lesson.stage, lesson.ability, 0, 0)
                result[key] = (current.0, current.1, current.2 + 1, current.3 + lesson.questions.count)
            }
            .map { CurriculumModuleSummary(id: $0.key, stage: $0.value.0, module: $0.value.1, lessonCount: $0.value.2, questionCount: $0.value.3) }
            .sorted { $0.id < $1.id }
    }
}

import Foundation

@main
struct QuestionBankRegressionTests {
    static func main() throws {
        // Evaluating the real catalog exercises the same lazy initializer as app launch.
        let lessons = MathContent.lessons
        precondition(!lessons.isEmpty, "The catalog must load at startup")
        precondition(Set(lessons.map(\.id)).count == lessons.count, "Duplicate lesson IDs")

        let expectedCounts = ["p-pattern": 24, "p-fraction": 5, "j-probability": 5]
        for (id, count) in expectedCounts {
            let lesson = lessons.first { $0.id == id }
            precondition(lesson?.questions.count == count, "Lost questions while merging \(id)")
        }

        let questions = lessons.flatMap(\.questions)
        let duplicateQuestionIDs = Dictionary(grouping: questions, by: \.id).filter { $0.value.count > 1 }.map(\.key)
        precondition(duplicateQuestionIDs.isEmpty, "Duplicate question IDs: \(duplicateQuestionIDs)")
        for question in questions {
            precondition(Set(question.choices.map(\.id)).count == question.choices.count,
                         "Duplicate choice IDs in \(question.id)")
            precondition(question.choices.contains { $0.id == question.answer },
                         "Invalid answer in \(question.id)")
        }

        // Persisted attempts depend on legacy question IDs retaining their original meaning.
        for (id, answer) in ["p-pattern-1": "15", "p-fraction-1": "1/2"] {
            precondition(questions.first { $0.id == id }?.answer == answer, "Changed meaning of \(id)")
        }
        precondition(questions.contains { $0.id != "p-pattern-1" && $0.answer == "37" },
                     "Lost the newer pattern question while preserving its legacy ID")
        precondition(questions.contains { $0.id != "p-fraction-1" && $0.answer == "64" },
                     "Lost the newer fraction question while preserving its legacy ID")
        for stage in Stage.allCases {
            precondition(!MathContent.lessons(for: stage).isEmpty, "Missing stage \(stage)")
        }
        let batches = (1...3).map { MathContent.simulationBatch($0) }
        let batchCounts = batches.map(\.count)
        precondition(batchCounts == [34, 33, 33], "Simulation batches must be 34/33/33, got \(batchCounts)")
        let batchedQuestions = batches.flatMap { $0 }
        precondition(Set(batchedQuestions.map(\.id)).count == 100, "Simulation batches must contain 100 unique questions")
        precondition(batchedQuestions.allSatisfy { !$0.explanation.isEmpty }, "Every simulation question needs an explanation")

        for lesson in lessons {
            precondition(!lesson.capabilities.isEmpty, "Lesson \(lesson.id) needs at least one capability")
        }

        let modelingLesson = Lesson(
            id: "test-modeling",
            title: "测试建模",
            ability: "建模推理",
            subject: .math,
            stage: .junior,
            minutes: 8,
            summary: "从真实情境提取变量",
            questions: []
        )
        precondition(modelingLesson.capabilities.contains(.modeling), "建模推理 must map to modeling")

        let activityIDs = MathContent.learningActivities.map(\.id)
        precondition(Set(activityIDs).count == activityIDs.count, "Duplicate activity IDs")
        precondition(MathContent.learningActivities.count >= 12, "Need at least 12 starter learning activities")

        let lessonIDs = Set(lessons.map(\.id))
        for activity in MathContent.learningActivities {
            precondition(!activity.title.isEmpty, "Activity \(activity.id) needs a title")
            precondition(!activity.prompt.isEmpty, "Activity \(activity.id) needs a prompt")
            precondition(!activity.capabilities.isEmpty, "Activity \(activity.id) needs capability tags")
            precondition((2...5).contains(activity.minutes), "Activity \(activity.id) must last 2-5 minutes")
            precondition(!activity.successCriteria.isEmpty, "Activity \(activity.id) needs success criteria")
            precondition(!activity.feedback.isEmpty, "Activity \(activity.id) needs feedback")
            if let lessonID = activity.lessonID {
                precondition(lessonIDs.contains(lessonID), "Activity \(activity.id) references missing lesson \(lessonID)")
            }
        }

        let stagesWithActivities = Set(MathContent.learningActivities.map(\.stage))
        precondition(stagesWithActivities == Set(Stage.allCases), "Primary and junior stages both need activities")
        precondition(!MathContent.activities(for: .modeling, stage: .primary).isEmpty, "Primary modeling activities missing")
        precondition(!MathContent.activities(for: .reasoning, stage: .junior).isEmpty, "Junior reasoning activities missing")
        print("PASS: catalog initialized; \(lessons.count) lessons, \(questions.count) unique questions; all merged questions retained")
    }
}

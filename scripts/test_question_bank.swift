import Foundation

@main
struct QuestionBankRegressionTests {
    static func main() throws {
        // Evaluating the real catalog exercises the same lazy initializer as app launch.
        let lessons = MathContent.lessons
        precondition(!lessons.isEmpty, "The catalog must load at startup")
        precondition(Set(lessons.map(\.id)).count == lessons.count, "Duplicate lesson IDs")

        // 合并逻辑不能丢题：扩充题库里的原始题目必须逐题保留。
        let retainedPrompts: [String: [String]] = [
            "p-fraction": [
                "一袋糖果的 3/8 是 24 颗，这袋糖果共有多少颗？",
                "5/6－1/3 的结果是？",
                "甲数的 2/5 等于乙数的 1/2，甲乙两数比是？",
                "1/2 和 1/3 哪个大？",
                "2/5+1/5=?"
            ],
            "j-probability": [
                "同时掷两枚公平骰子，点数和为 7 的概率是？",
                "从 1 到 10 中随机取一个数，取到偶数的概率是？",
                "事件 A 发生概率为 0.7，则事件 A 不发生的概率是？"
            ]
        ]
        for (id, prompts) in retainedPrompts {
            guard let lesson = lessons.first(where: { $0.id == id }) else {
                preconditionFailure("Missing lesson \(id)")
            }
            let existing = Set(lesson.questions.map(\.prompt))
            for prompt in prompts where !existing.contains(prompt) {
                preconditionFailure("Lost question while merging \(id): \(prompt)")
            }
        }
        // p-pattern 有 24 道扩充题，已超过每点最低题量，必须整批保留而不被派生题替换。
        let patternCount = lessons.first { $0.id == "p-pattern" }?.questions.count ?? -1
        precondition(patternCount == 24, "p-pattern must keep all 24 merged questions, got \(patternCount)")

        let questions = lessons.flatMap(\.questions)
        let duplicateQuestionIDs = Dictionary(grouping: questions, by: \.id).filter { $0.value.count > 1 }.map(\.key)
        precondition(duplicateQuestionIDs.isEmpty, "Duplicate question IDs: \(duplicateQuestionIDs)")
        for question in questions {
            precondition(Set(question.choices.map(\.id)).count == question.choices.count,
                         "Duplicate choice IDs in \(question.id)")
            precondition(question.choices.count >= 3, "\(question.id) needs at least three choices")
            precondition(question.choices.contains { $0.id == question.answer },
                         "Invalid answer in \(question.id)")
            precondition(!question.prompt.isEmpty, "\(question.id) needs a prompt")
            precondition(!question.explanation.isEmpty, "\(question.id) needs an explanation")
        }

        // 每个知识点都必须有配套习题，且不低于最低题量。
        var answerSlots = [0, 0, 0, 0]
        for lesson in lessons {
            precondition(lesson.questions.count >= LessonPracticeFactory.questionsPerPoint,
                         "Lesson \(lesson.id) only has \(lesson.questions.count) questions")
            let slotSum = lesson.questions.reduce(0) { total, question in
                guard let slot = question.choices.firstIndex(where: { $0.id == question.answer }) else { return total }
                if slot < answerSlots.count { answerSlots[slot] += 1 }
                return total + 1
            }
            precondition(slotSum == lesson.questions.count, "Lesson \(lesson.id) has an answer outside its choices")
        }
        // 答案位置必须分散，不能整套题都落在 A。
        precondition(answerSlots.allSatisfy { $0 > 0 }, "Answer slots are unbalanced: \(answerSlots)")
        let maxSlotShare = Double(answerSlots.max() ?? 0) / Double(questions.count)
        precondition(maxSlotShare < 0.5, "One answer slot holds \(maxSlotShare) of all questions")

        // 练习批次要能覆盖整个题组，不能丢题。
        for lesson in lessons {
            let batches = (0..<LessonPracticeFactory.batchCount(for: lesson.questions))
                .map { LessonPracticeFactory.batch(lesson.questions, index: $0) }
            precondition(batches.flatMap { $0 }.count == lesson.questions.count,
                         "Batching lost questions in \(lesson.id)")
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

        let primary = MathContent.lessons(for: .primary)
        let junior = MathContent.lessons(for: .junior)
        print("PASS: catalog initialized; \(lessons.count) lessons (\(primary.count) primary / \(junior.count) junior), "
              + "\(questions.count) unique questions, every lesson >= \(LessonPracticeFactory.questionsPerPoint); "
              + "answer slots A/B/C/D = \(answerSlots)")
    }
}

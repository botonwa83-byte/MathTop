import Foundation

enum Stage: String, Codable, CaseIterable { case primary = "小学", junior = "初中" }
enum Subject: String, Codable { case math = "数学", english = "英语" }
enum QuestionKind: String, Codable { case choice, fill, reorder, listening }

struct QuestionChoice: Codable, Identifiable, Hashable { let id: String; let text: String }
struct Question: Codable, Identifiable, Hashable {
    let id: String; let prompt: String; let kind: QuestionKind; let choices: [QuestionChoice]
    let answer: String; let explanation: String
}
struct Lesson: Codable, Identifiable, Hashable {
    let id: String; let title: String; let ability: String; let subject: Subject; let stage: Stage
    let minutes: Int; let summary: String; let questions: [Question]
}
struct Attempt: Codable, Identifiable { let id: UUID; let questionID: String; let lessonID: String; let correct: Bool; let date: Date }

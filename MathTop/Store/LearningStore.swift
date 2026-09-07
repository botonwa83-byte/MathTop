import Foundation
import SwiftUI

final class LearningStore: ObservableObject {
    @Published private(set) var completedLessonIDs: Set<String> = []
    @Published private(set) var attempts: [Attempt] = []
    var incorrectAttempts: [Attempt] { attempts.filter { !$0.correct } }
    var dueReviewCount: Int { attempts.filter { ReviewScheduler.isDue($0) }.count }
    private let defaults = UserDefaults.standard
    init() { load() }
    func markLessonCompleted(_ lesson: Lesson) { completedLessonIDs.insert(lesson.id); save() }
    func recordAttempt(questionID: String, lessonID: String, correct: Bool) { attempts.append(Attempt(id: UUID(), questionID: questionID, lessonID: lessonID, correct: correct, date: Date())); save() }
    func progress(for lessons: [Lesson]) -> Double { guard !lessons.isEmpty else { return 0 }; return Double(lessons.filter { completedLessonIDs.contains($0.id) }.count) / Double(lessons.count) }
    private func load() { if let ids = defaults.array(forKey: "completedLessonIDs") as? [String] { completedLessonIDs = Set(ids) }; if let data = defaults.data(forKey: "attempts"), let value = try? JSONDecoder().decode([Attempt].self, from: data) { attempts = value } }
    private func save() { defaults.set(Array(completedLessonIDs), forKey: "completedLessonIDs"); if let data = try? JSONEncoder().encode(attempts) { defaults.set(data, forKey: "attempts") } }
}

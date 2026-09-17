import Foundation
import SwiftUI

final class LearningStore: ObservableObject {
    @Published private(set) var completedLessonIDs: Set<String> = []
    @Published private(set) var attempts: [Attempt] = []
    @Published private(set) var activityEvents: [LearningActivityEvent] = []
    @Published private(set) var studySessions: [StudySession] = []
    @Published private(set) var streak: Int = 0
    @Published private(set) var lastStudyDate: Date?

    /// 错题本：同一道题以最近一次作答为准，重做答对后自动消化，
    /// 避免错题只增不减、复习队列永远清不空。
    var incorrectAttempts: [Attempt] { latestAttempts.filter { !$0.correct } }

    /// 每道题保留最近一次作答（按时间倒序，最新在前）。
    var latestAttempts: [Attempt] {
        var latest: [String: Attempt] = [:]
        for attempt in attempts {
            if let existing = latest[attempt.questionID], existing.date > attempt.date { continue }
            latest[attempt.questionID] = attempt
        }
        return latest.values.sorted { $0.date > $1.date }
    }

    /// 到期复习只统计尚待消化的错题，与首页「N 道错题该复习了」文案一致。
    var dueReviewCount: Int {
        incorrectAttempts.filter { ReviewScheduler.isDue($0, now: now(), calendar: calendar) }.count
    }
    var completedSessionsCount: Int { studySessions.filter(\.isCompleted).count }
    var reflectionCount: Int { activityEvents.filter { $0.mode == .reflect }.count }

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        load()
    }

    func markLessonCompleted(_ lesson: Lesson) {
        completedLessonIDs.insert(lesson.id)
        updateStreak(on: now())
        save()
    }

    func recordAttempt(questionID: String, lessonID: String, correct: Bool) {
        attempts.append(Attempt(id: UUID(), questionID: questionID, lessonID: lessonID, correct: correct, date: now()))
        save()
    }

    func progress(for lessons: [Lesson]) -> Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(lessons.filter { completedLessonIDs.contains($0.id) }.count) / Double(lessons.count)
    }

    func upsertStudySession(_ session: StudySession) {
        if let index = studySessions.firstIndex(where: { $0.id == session.id }) {
            studySessions[index] = session
        } else {
            studySessions.append(session)
        }
        save()
    }

    func session(on date: Date = Date(), stage: Stage, calendar: Calendar = .current) -> StudySession? {
        studySessions.first { session in
            session.stage == stage && calendar.isDate(session.date, inSameDayAs: date)
        }
    }

    func completeActivity(_ activity: LearningActivity, in session: StudySession, score: Double = 1, note: String? = nil) {
        var storedSession = studySessions.first(where: { $0.id == session.id }) ?? session
        guard !storedSession.completedActivityIDs.contains(activity.id) else { return }
        storedSession.completedActivityIDs.insert(activity.id)
        if let index = studySessions.firstIndex(where: { $0.id == storedSession.id }) {
            studySessions[index] = storedSession
        } else {
            studySessions.append(storedSession)
        }

        activityEvents.append(
            LearningActivityEvent(
                id: UUID(),
                activityID: activity.id,
                sessionID: storedSession.id,
                lessonID: activity.lessonID,
                mode: activity.mode,
                capabilities: activity.capabilities,
                score: max(0, min(score, 1)),
                note: note,
                date: now()
            )
        )
        updateStreak(on: now())
        save()
    }

    private func updateStreak(on date: Date) {
        let today = calendar.startOfDay(for: date)
        guard let lastStudyDate else {
            streak = 1
            self.lastStudyDate = today
            return
        }

        let lastDay = calendar.startOfDay(for: lastStudyDate)
        if calendar.isDate(lastDay, inSameDayAs: today) {
            if streak == 0 { streak = 1 }
            return
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        if let yesterday, calendar.isDate(lastDay, inSameDayAs: yesterday) {
            streak += 1
        } else {
            streak = 1
        }
        self.lastStudyDate = today
    }

    private func load() {
        if let ids = defaults.array(forKey: Keys.completedLessonIDs) as? [String] {
            completedLessonIDs = Set(ids)
        }
        if let data = defaults.data(forKey: Keys.attempts), let value = try? JSONDecoder().decode([Attempt].self, from: data) {
            attempts = value
        }
        if let data = defaults.data(forKey: Keys.activityEvents), let value = try? JSONDecoder().decode([LearningActivityEvent].self, from: data) {
            activityEvents = value
        }
        if let data = defaults.data(forKey: Keys.studySessions), let value = try? JSONDecoder().decode([StudySession].self, from: data) {
            studySessions = value
        }
        streak = defaults.integer(forKey: Keys.streak)
        lastStudyDate = defaults.object(forKey: Keys.lastStudyDate) as? Date
    }

    private func save() {
        defaults.set(Array(completedLessonIDs), forKey: Keys.completedLessonIDs)
        if let data = try? JSONEncoder().encode(attempts) {
            defaults.set(data, forKey: Keys.attempts)
        }
        if let data = try? JSONEncoder().encode(activityEvents) {
            defaults.set(data, forKey: Keys.activityEvents)
        }
        if let data = try? JSONEncoder().encode(studySessions) {
            defaults.set(data, forKey: Keys.studySessions)
        }
        defaults.set(streak, forKey: Keys.streak)
        defaults.set(lastStudyDate, forKey: Keys.lastStudyDate)
    }

    private enum Keys {
        static let completedLessonIDs = "completedLessonIDs"
        static let attempts = "attempts"
        static let activityEvents = "learningActivityEvents"
        static let studySessions = "studySessions"
        static let streak = "learningStreak"
        static let lastStudyDate = "lastStudyDate"
    }
}

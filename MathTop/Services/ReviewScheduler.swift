import Foundation

enum ReviewScheduler {
    static func nextDate(after date: Date, correct: Bool, calendar: Calendar = .current) -> Date {
        let days = correct ? 7 : 1
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    static func isDue(_ attempt: Attempt, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let days = attempt.correct ? 7 : 1
        guard let due = calendar.date(byAdding: .day, value: days, to: attempt.date) else { return true }
        return due <= now
    }
}

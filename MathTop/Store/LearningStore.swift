import Foundation
import SwiftUI

final class LearningStore: ObservableObject {
    @Published private(set) var completedLessonIDs: Set<String> = []
    /// 作答记录：刻意不做 @Published 自动发布。
    /// 做题页每次确认都会写一条记录，若自动通知，四个 Tab 会跟着整棵重算，点「下一题」明显卡。
    /// 做题过程静默写入（notify: false），离开做题页再统一通知一次。
    private(set) var attempts: [Attempt] = []
    @Published private(set) var activityEvents: [LearningActivityEvent] = []
    @Published private(set) var studySessions: [StudySession] = []
    @Published private(set) var streak: Int = 0
    @Published private(set) var lastStudyDate: Date?

    // MARK: 派生数据（按版本号缓存，写操作后统一失效）
    //
    // 这些结果会被多个 Tab（今日 / 能力地图 / 知识本 / 我的）在同一个渲染周期内反复读取。
    // 原来每次访问都全量扫描 attempts / activityEvents，「确认答案」这类高频操作会把主线程堵住。
    private var dataVersion = 0
    private var derivedVersion = -1
    private var cachedLatestAttempts: [Attempt] = []
    private var cachedIncorrectAttempts: [Attempt] = []
    private var cachedDueReviewCount = 0
    private var cachedCompletedSessions = 0
    private var cachedReflections = 0
    private var cachedSummary: GrowthSummary?

    private func refreshDerivedIfNeeded() {
        guard derivedVersion != dataVersion else { return }
        derivedVersion = dataVersion

        var latest: [String: Attempt] = [:]
        for attempt in attempts {
            if let existing = latest[attempt.questionID], existing.date > attempt.date { continue }
            latest[attempt.questionID] = attempt
        }
        cachedLatestAttempts = latest.values.sorted { $0.date > $1.date }
        cachedIncorrectAttempts = cachedLatestAttempts.filter { !$0.correct }
        cachedDueReviewCount = cachedIncorrectAttempts.filter { ReviewScheduler.isDue($0, now: now(), calendar: calendar) }.count
        cachedCompletedSessions = studySessions.filter(\.isCompleted).count
        cachedReflections = activityEvents.filter { $0.mode == .reflect }.count
        cachedSummary = GrowthSummaryService.make(store: self, now: now(), calendar: calendar)
    }

    /// 错题本：同一道题以最近一次作答为准，重做答对后自动消化，
    /// 避免错题只增不减、复习队列永远清不空。
    var incorrectAttempts: [Attempt] {
        refreshDerivedIfNeeded()
        return cachedIncorrectAttempts
    }

    /// 每道题保留最近一次作答（按时间倒序，最新在前）。
    var latestAttempts: [Attempt] {
        refreshDerivedIfNeeded()
        return cachedLatestAttempts
    }

    /// 成长摘要：五维能力、趋势与建议，一次渲染周期内只算一次。
    var growthSummary: GrowthSummary {
        refreshDerivedIfNeeded()
        return cachedSummary ?? GrowthSummaryService.make(store: self, now: now(), calendar: calendar)
    }

    /// 到期复习只统计尚待消化的错题，与首页「N 道错题该复习了」文案一致。
    var dueReviewCount: Int {
        refreshDerivedIfNeeded()
        return cachedDueReviewCount
    }
    var completedSessionsCount: Int {
        refreshDerivedIfNeeded()
        return cachedCompletedSessions
    }
    var reflectionCount: Int {
        refreshDerivedIfNeeded()
        return cachedReflections
    }

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        load()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.flushNowSync() }
    }

    func markLessonCompleted(_ lesson: Lesson) {
        completedLessonIDs.insert(lesson.id)
        updateStreak(on: now())
        didChangeData()
    }

    /// 记录一次作答。`notify: false` 用于做题过程中：数据照写，但不触发视图重算。
    func recordAttempt(questionID: String, lessonID: String, correct: Bool, notify: Bool = true) {
        attempts.append(Attempt(id: UUID(), questionID: questionID, lessonID: lessonID, correct: correct, date: now()))
        didChangeData(notify: notify)
    }

    /// 静默写入后统一补一次刷新（离开做题页时调用）。
    func notifyDataChanged() {
        objectWillChange.send()
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
        didChangeData()
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
        didChangeData()
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

    /// 数据变更统一入口：派生缓存失效 + 落盘。
    /// `attempts` 不是 @Published，改它时需要显式发布才会刷新视图。
    private func didChangeData(notify: Bool = true) {
        dataVersion += 1
        if notify { objectWillChange.send() }
        save()
    }

    /// 合并写入：一次作答里的多次改动只在 0.25 秒后落盘一次。
    private var needsSave = false
    private var saveScheduled = false

    private func save() {
        needsSave = true
        guard !saveScheduled else { return }
        saveScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.saveScheduled = false
            if self.needsSave { self.flushNow() }
        }
    }

    /// JSON 编码与写盘放到后台队列：作答记录累积到几百上千条时，
    /// 主线程编码会在「确认答案」后造成肉眼可见的卡顿。
    private let persistQueue = DispatchQueue(label: "mathtop.learningstore.persist", qos: .utility)

    /// 立即落盘（异步编码 + 写入，不阻塞交互）。
    func flushNow() {
        needsSave = false
        let snapshot = snapshotForPersist()
        let defaults = self.defaults
        persistQueue.async { snapshot.write(to: defaults) }
    }

    /// 同步落盘：App 进入后台时调用，确保进程被挂起前数据已写稳。
    func flushNowSync() {
        needsSave = false
        snapshotForPersist().write(to: defaults)
    }

    private func snapshotForPersist() -> PersistSnapshot {
        PersistSnapshot(
            completedLessonIDs: Array(completedLessonIDs),
            attempts: attempts,
            activityEvents: activityEvents,
            studySessions: studySessions,
            streak: streak,
            lastStudyDate: lastStudyDate
        )
    }

    /// 落盘快照：值类型拷贝一份再编码，避免后台队列访问正在变化的状态。
    private struct PersistSnapshot {
        let completedLessonIDs: [String]
        let attempts: [Attempt]
        let activityEvents: [LearningActivityEvent]
        let studySessions: [StudySession]
        let streak: Int
        let lastStudyDate: Date?

        func write(to defaults: UserDefaults) {
            defaults.set(completedLessonIDs, forKey: Keys.completedLessonIDs)
            if let data = try? JSONEncoder().encode(attempts) { defaults.set(data, forKey: Keys.attempts) }
            if let data = try? JSONEncoder().encode(activityEvents) { defaults.set(data, forKey: Keys.activityEvents) }
            if let data = try? JSONEncoder().encode(studySessions) { defaults.set(data, forKey: Keys.studySessions) }
            defaults.set(streak, forKey: Keys.streak)
            defaults.set(lastStudyDate, forKey: Keys.lastStudyDate)
        }
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

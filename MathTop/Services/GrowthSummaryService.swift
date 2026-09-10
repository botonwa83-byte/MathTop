import Foundation

struct CapabilityGrowthItem: Identifiable, Hashable {
    let capability: Capability
    let snapshot: CapabilitySnapshot
    let recommendation: String

    var id: Capability { capability }
}

struct GrowthSummary {
    let completed: Int
    let total: Int
    let attempts: Int
    let incorrect: Int
    let capabilitySnapshots: [CapabilitySnapshot]
    let topCapability: CapabilityGrowthItem?
    let weakCapability: CapabilityGrowthItem?
    let streak: Int
    let sessions: Int
    let reflections: Int
    let sevenDayActivityCounts: [Int]
    let nextStep: String

    var mastery: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}

enum GrowthSummaryService {
    static func make(store: LearningStore, now: Date = Date(), calendar: Calendar = .current) -> GrowthSummary {
        let snapshots = makeCapabilitySnapshots(events: store.activityEvents, attempts: store.attempts, lessons: MathContent.lessons, now: now, calendar: calendar)
        let sortedByMastery = snapshots.sorted { lhs, rhs in
            if lhs.mastery == rhs.mastery { return lhs.capability.rawValue < rhs.capability.rawValue }
            return lhs.mastery > rhs.mastery
        }
        let top = sortedByMastery.first(where: { $0.practiceCount > 0 }).map { item(for: $0, weak: false) }
        // 没有任何学习记录时不给「待加强」结论，避免对刚打开 App 的用户凭空下判断。
        let hasAnyRecord = !store.activityEvents.isEmpty || !store.attempts.isEmpty
        let weak = hasAnyRecord
            ? snapshots.sorted { lhs, rhs in
                if lhs.mastery == rhs.mastery { return lhs.practiceCount < rhs.practiceCount }
                return lhs.mastery < rhs.mastery
            }.first.map { item(for: $0, weak: true) }
            : nil

        let nextStep: String
        if store.activityEvents.isEmpty && store.attempts.isEmpty {
            nextStep = "先完成今日任务包，用一道题建立学习记录。"
        } else if let weak {
            nextStep = "下一次优先练 \(weak.capability.title)：\(weak.recommendation)"
        } else {
            nextStep = "继续完成今日任务包，保持理解、练习、迁移、复盘闭环。"
        }

        return GrowthSummary(
            completed: store.completedLessonIDs.count,
            total: MathContent.lessons.count,
            attempts: store.attempts.count,
            incorrect: store.incorrectAttempts.count,
            capabilitySnapshots: snapshots,
            topCapability: top,
            weakCapability: weak,
            streak: store.streak,
            sessions: store.completedSessionsCount,
            reflections: store.reflectionCount,
            sevenDayActivityCounts: sevenDayActivityCounts(events: store.activityEvents, now: now, calendar: calendar),
            nextStep: nextStep
        )
    }

    static func makeCapabilitySnapshots(events: [LearningActivityEvent], attempts: [Attempt], lessons: [Lesson], now: Date = Date(), calendar: Calendar = .current) -> [CapabilitySnapshot] {
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentEvents = events.filter { $0.date >= cutoff && $0.date <= now }
        let recentAttempts = attempts.filter { $0.date >= cutoff && $0.date <= now }
        let lessonsByID = Dictionary(uniqueKeysWithValues: lessons.map { ($0.id, $0) })

        return Capability.allCases.map { capability in
            let matchingEvents = recentEvents.filter { $0.capabilities.contains(capability) }
            let matchingAttempts = recentAttempts.filter { attempt in
                lessonsByID[attempt.lessonID]?.capabilities.contains(capability) == true
            }
            let eventScore = matchingEvents.reduce(0.0) { total, event in
                total + modeWeight(event.mode) * max(0, min(event.score, 1))
            }
            let attemptScore = matchingAttempts.reduce(0.0) { total, attempt in
                total + (attempt.correct ? 0.06 : -0.05)
            }
            let mastery = max(0, min(1, eventScore + attemptScore))
            let latestDate = (matchingEvents.map(\.date) + matchingAttempts.map(\.date)).max()
            let practiceCount = matchingEvents.count + matchingAttempts.count
            let trend = trendForCapability(capability, events: recentEvents, attempts: recentAttempts, lessonsByID: lessonsByID, now: now, calendar: calendar)
            return CapabilitySnapshot(capability: capability, mastery: mastery, practiceCount: practiceCount, trend: trend, updatedAt: latestDate)
        }
    }

    static func sevenDayActivityCounts(events: [LearningActivityEvent], now: Date = Date(), calendar: Calendar = .current) -> [Int] {
        (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: now) ?? now
            return events.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
        }
    }

    private static func modeWeight(_ mode: LearningMode) -> Double {
        switch mode {
        case .understand: return 0.05
        case .practice: return 0.10
        case .transfer: return 0.15
        case .reflect: return 0.08
        case .focus: return 0.06
        }
    }

    private static func trendForCapability(_ capability: Capability, events: [LearningActivityEvent], attempts: [Attempt], lessonsByID: [String: Lesson], now: Date, calendar: Calendar) -> CapabilityTrend {
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let recentEvents = events.filter { $0.date >= sevenDaysAgo && $0.capabilities.contains(capability) }
        let recentAttempts = attempts.filter { attempt in
            attempt.date >= sevenDaysAgo && lessonsByID[attempt.lessonID]?.capabilities.contains(capability) == true
        }
        let incorrectCount = recentAttempts.filter { !$0.correct }.count
        if incorrectCount >= 2 { return .needsAttention }
        if !recentEvents.isEmpty || recentAttempts.contains(where: \.correct) { return .rising }
        return .steady
    }

    private static func item(for snapshot: CapabilitySnapshot, weak: Bool) -> CapabilityGrowthItem {
        CapabilityGrowthItem(capability: snapshot.capability, snapshot: snapshot, recommendation: recommendation(for: snapshot.capability, weak: weak))
    }

    private static func recommendation(for capability: Capability, weak: Bool) -> String {
        switch capability {
        case .numberSense: return weak ? "先做估算，再做精确计算。" : "继续用估算检查答案。"
        case .modeling: return weak ? "先写变量含义，再列数量关系。" : "尝试把生活情境写成方程或函数。"
        case .reasoning: return weak ? "每一步写出依据，再下结论。" : "用反例或检验巩固结论。"
        case .expression: return weak ? "用一句话说清为什么这样做。" : "把解法讲给同学听。"
        case .focusReflection: return weak ? "复盘一次卡点，并写下下次检查动作。" : "保持短时专注和错因记录。"
        }
    }
}

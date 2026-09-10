# Capability Learning System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 MathTop 从课程题库升级为围绕数感、建模、推理、表达、专注与复盘五类能力运转的每日学习产品。

**Architecture:** 保留现有 `LearningStore` 作为本地状态入口，在现有模型、内容、服务和 SwiftUI 视图上增量扩展。核心能力计算和每日任务编排放在纯 Swift 服务中，先用脚本测试验证，再让首页、能力地图、知识本和成长摘要读取同一套会话与活动数据。

**Tech Stack:** Swift 5.0, SwiftUI, Foundation, UserDefaults, iOS 16.0, `xcrun --sdk macosx swiftc`, `xcodebuild`.

**Spec:** `docs/superpowers/specs/2026-09-10-capability-learning-system-design.md`

## Global Constraints

- iOS deployment target remains `"16.0"`.
- 本阶段以数学为主线，英语只保留轻量热身入口。
- 不建设账号体系、云同步、支付、社交排名、教师后台和完整英语课程。
- `completedLessonIDs` and `attempts` must remain readable from existing `UserDefaults` keys.
- 新增数据解码失败时回退为空集合，并保留旧数据键。
- 所有写入仍通过 `LearningStore.save()` 完成，视图不直接写 `UserDefaults`。
- 空题库、空历史记录、缺少能力事件时显示可完成内容，不出现空白页或崩溃。
- 任务包总时长控制在 10 到 15 分钟。
- 所有文本和布局适配中文长文本与 iOS 16 SwiftUI API。

---

## File Structure

- Modify `MathTop/Models/LearningModels.swift`: add capability, activity, session, event, and snapshot models while keeping `Lesson`, `Question`, and `Attempt` compatible.
- Modify `MathTop/Content/MathContent.swift`: attach capability tags to lessons and add the first local transfer/reflection/focus activity catalog.
- Modify `MathTop/Store/LearningStore.swift`: persist activity events, study sessions, streak, and last study date through the same save path as legacy state.
- Modify `MathTop/Services/GrowthSummaryService.swift`: calculate capability snapshots, 7-day trend, top/weak capability, streak, and next-step copy from store data.
- Modify `MathTop/Services/DailyPlanService.swift`: build a 10-15 minute `StudySession` that prioritizes due review, weak capability, next lesson, transfer, and reflection.
- Modify `MathTop/App/MathTopApp.swift`: update Home, capability map, notebook, practice flow, new activity scenes, profile, and growth summary UI.
- Modify `scripts/test_question_bank.swift`: extend catalog regression checks to capability tags and activity metadata.
- Create `scripts/test_learning_system.swift`: script-level service/store regression tests for the new learning system.
- Create `scripts/test_learning_system.sh`: compile and run the learning-system regression tests with an isolated module cache.

No new app-target Swift files are required for this pass. Keeping view additions in `MathTop/App/MathTopApp.swift` avoids project-file churn while the existing `.xcodeproj` is already dirty.

---

### Task 1: Capability Models And Content Activity Catalog

**Files:**
- Modify: `MathTop/Models/LearningModels.swift`
- Modify: `MathTop/Content/MathContent.swift`
- Modify: `scripts/test_question_bank.swift`

**Interfaces:**
- Consumes: existing `Stage`, `Subject`, `QuestionKind`, `Question`, `Lesson`, `Attempt`, `MathContent.lessons`.
- Produces: `Capability`, `LearningMode`, `CapabilityTrend`, `CapabilitySnapshot`, `LearningActivity`, `LearningActivityEvent`, `StudySession`.
- Produces: `Lesson.capabilities: [Capability]` with `Lesson.init(..., capabilities: [Capability]? = nil)` and decoding fallback.
- Produces: `MathContent.learningActivities: [LearningActivity]`.
- Produces: `MathContent.activities(for capability: Capability, stage: Stage) -> [LearningActivity]`.
- Produces: `MathContent.activities(for stage: Stage) -> [LearningActivity]`.

- [ ] **Step 1: Extend the content regression test first**

Add these checks near the end of `scripts/test_question_bank.swift`, before the final `print`:

```swift
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
```

- [ ] **Step 2: Run the content test to verify it fails**

Run:

```bash
scripts/test_question_bank.sh
```

Expected: FAIL with compiler errors for missing `Capability`, `LearningActivity`, `Lesson.capabilities`, and `MathContent.learningActivities`.

- [ ] **Step 3: Add capability and activity models**

Replace `MathTop/Models/LearningModels.swift` with model definitions that preserve existing public names:

```swift
import Foundation

enum Stage: String, Codable, CaseIterable { case primary = "小学", junior = "初中" }
enum Subject: String, Codable { case math = "数学", english = "英语" }
enum QuestionKind: String, Codable { case choice, fill, reorder, listening }

enum Capability: String, Codable, CaseIterable, Identifiable, Hashable {
    case numberSense
    case modeling
    case reasoning
    case expression
    case focusReflection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numberSense: return "数感"
        case .modeling: return "建模"
        case .reasoning: return "推理"
        case .expression: return "表达"
        case .focusReflection: return "专注与复盘"
        }
    }

    var shortTitle: String {
        switch self {
        case .numberSense: return "数感"
        case .modeling: return "建模"
        case .reasoning: return "推理"
        case .expression: return "表达"
        case .focusReflection: return "复盘"
        }
    }

    var systemImage: String {
        switch self {
        case .numberSense: return "number"
        case .modeling: return "point.3.connected.trianglepath.dotted"
        case .reasoning: return "lightbulb"
        case .expression: return "text.bubble"
        case .focusReflection: return "timer"
        }
    }

    static func defaultCapabilities(forAbility ability: String) -> [Capability] {
        var result: [Capability] = []
        func add(_ capability: Capability) {
            if !result.contains(capability) { result.append(capability) }
        }

        if ability.contains("数") || ability.contains("运算") || ability.contains("分数") || ability.contains("小数") || ability.contains("有理") {
            add(.numberSense)
        }
        if ability.contains("解决") || ability.contains("应用") || ability.contains("方程") || ability.contains("函数") || ability.contains("建模") || ability.contains("速度") || ability.contains("比例") {
            add(.modeling)
        }
        if ability.contains("规律") || ability.contains("几何") || ability.contains("图形") || ability.contains("证明") || ability.contains("概率") || ability.contains("统计") || ability.contains("推理") {
            add(.reasoning)
        }
        if result.isEmpty { add(.reasoning) }
        return result
    }
}

enum LearningMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case understand
    case practice
    case transfer
    case reflect
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .understand: return "理解"
        case .practice: return "练习"
        case .transfer: return "迁移"
        case .reflect: return "表达复盘"
        case .focus: return "专注"
        }
    }
}

enum CapabilityTrend: String, Codable, Hashable {
    case rising
    case steady
    case needsAttention

    var title: String {
        switch self {
        case .rising: return "上升"
        case .steady: return "稳定"
        case .needsAttention: return "需加强"
        }
    }
}

struct QuestionChoice: Codable, Identifiable, Hashable { let id: String; let text: String }
struct Question: Codable, Identifiable, Hashable {
    let id: String; let prompt: String; let kind: QuestionKind; let choices: [QuestionChoice]
    let answer: String; let explanation: String
    let source: String?
    init(id: String, prompt: String, kind: QuestionKind, choices: [QuestionChoice], answer: String, explanation: String, source: String? = nil) {
        self.id = id; self.prompt = prompt; self.kind = kind; self.choices = choices; self.answer = answer; self.explanation = explanation; self.source = source
    }
}

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let ability: String
    let subject: Subject
    let stage: Stage
    let minutes: Int
    let summary: String
    let questions: [Question]
    let capabilities: [Capability]

    init(id: String, title: String, ability: String, subject: Subject, stage: Stage, minutes: Int, summary: String, questions: [Question], capabilities: [Capability]? = nil) {
        self.id = id
        self.title = title
        self.ability = ability
        self.subject = subject
        self.stage = stage
        self.minutes = minutes
        self.summary = summary
        self.questions = questions
        self.capabilities = capabilities ?? Capability.defaultCapabilities(forAbility: ability)
    }
}

struct Attempt: Codable, Identifiable, Hashable { let id: UUID; let questionID: String; let lessonID: String; let correct: Bool; let date: Date }

struct LearningActivity: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let mode: LearningMode
    let prompt: String
    let lessonID: String?
    let questionIDs: [String]
    let stage: Stage
    let capabilities: [Capability]
    let minutes: Int
    let successCriteria: String
    let feedback: String
    let choices: [String]

    init(id: String, title: String, mode: LearningMode, prompt: String, lessonID: String?, questionIDs: [String] = [], stage: Stage, capabilities: [Capability], minutes: Int, successCriteria: String, feedback: String, choices: [String] = []) {
        self.id = id
        self.title = title
        self.mode = mode
        self.prompt = prompt
        self.lessonID = lessonID
        self.questionIDs = questionIDs
        self.stage = stage
        self.capabilities = capabilities
        self.minutes = minutes
        self.successCriteria = successCriteria
        self.feedback = feedback
        self.choices = choices
    }
}

struct LearningActivityEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let activityID: String
    let sessionID: String
    let lessonID: String?
    let mode: LearningMode
    let capabilities: [Capability]
    let score: Double
    let note: String?
    let date: Date
}

struct StudySession: Codable, Identifiable, Hashable {
    var id: String
    var date: Date
    var stage: Stage
    var activities: [LearningActivity]
    var completedActivityIDs: Set<String>

    var estimatedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var isCompleted: Bool { !activities.isEmpty && activities.allSatisfy { completedActivityIDs.contains($0.id) } }
}

struct CapabilitySnapshot: Codable, Identifiable, Hashable {
    let capability: Capability
    let mastery: Double
    let practiceCount: Int
    let trend: CapabilityTrend
    let updatedAt: Date?

    var id: Capability { capability }
}
```

- [ ] **Step 4: Add decoding fallback for `Lesson.capabilities`**

Append this extension below `Lesson` in `MathTop/Models/LearningModels.swift`:

```swift
extension Lesson {
    private enum CodingKeys: String, CodingKey {
        case id, title, ability, subject, stage, minutes, summary, questions, capabilities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        ability = try container.decode(String.self, forKey: .ability)
        subject = try container.decode(Subject.self, forKey: .subject)
        stage = try container.decode(Stage.self, forKey: .stage)
        minutes = try container.decode(Int.self, forKey: .minutes)
        summary = try container.decode(String.self, forKey: .summary)
        questions = try container.decode([Question].self, forKey: .questions)
        capabilities = try container.decodeIfPresent([Capability].self, forKey: .capabilities) ?? Capability.defaultCapabilities(forAbility: ability)
    }
}
```

- [ ] **Step 5: Add the local learning activity catalog**

In `MathTop/Content/MathContent.swift`, add these members inside `enum MathContent`, before `static var lessons`:

```swift
    static let learningActivities: [LearningActivity] = [
        LearningActivity(id: "act-p-shopping-discount", title: "超市折扣预算", mode: .transfer, prompt: "书包 80 元打九折，笔记本 12 元买 2 本减 3 元。先估算总价，再写出精确算式。", lessonID: "p-percent", stage: .primary, capabilities: [.numberSense, .modeling], minutes: 4, successCriteria: "能写出现价关系，并说明估算值和精确值为什么接近。", feedback: "你把折扣情境转成了数量关系，这是建模练习。"),
        LearningActivity(id: "act-p-speed-trip", title: "放学路线规划", mode: .transfer, prompt: "家到图书馆 3 千米，步行每小时 4 千米，骑车每小时 12 千米。比较两种方式需要多久。", lessonID: "p-speed", stage: .primary, capabilities: [.modeling, .numberSense], minutes: 4, successCriteria: "能使用时间=路程÷速度，并用分钟表达结果。", feedback: "你能把速度、路程、时间放进同一个模型。"),
        LearningActivity(id: "act-p-area-plan", title: "小花园面积规划", mode: .transfer, prompt: "长 8 米、宽 5 米的花园中间留一条宽 1 米的小路。估计还能种花的面积。", lessonID: "p-area", stage: .primary, capabilities: [.modeling, .reasoning], minutes: 5, successCriteria: "能说明总面积、小路面积和剩余面积之间的关系。", feedback: "你在真实空间中使用面积关系完成了迁移。"),
        LearningActivity(id: "act-p-explain-fraction", title: "讲清分数比较", mode: .reflect, prompt: "向同学解释为什么 3/4 比 2/3 大，只说一句关键理由。", lessonID: "p-fraction", stage: .primary, capabilities: [.numberSense, .expression], minutes: 2, successCriteria: "能使用通分、画图或同整体比较中的一种理由。", feedback: "能说清理由，说明你不只是记答案。", choices: ["通分后比较", "画同样大小的图", "和 1 的距离比较"]),
        LearningActivity(id: "act-p-focus-calculation", title: "3 分钟计算专注", mode: .focus, prompt: "选择 2 道今天的计算题，3 分钟内只做审题、列式、检查三件事。", lessonID: "p-four", stage: .primary, capabilities: [.focusReflection, .numberSense], minutes: 3, successCriteria: "能完整经历审题、列式、检查，不中途切换任务。", feedback: "专注完成比多刷题更能稳定正确率。"),
        LearningActivity(id: "act-p-reflect-mistake", title: "错因定位卡", mode: .reflect, prompt: "从最近一次错题中选择卡点：审题、计算、表达、验证。", lessonID: nil, stage: .primary, capabilities: [.focusReflection, .expression], minutes: 2, successCriteria: "能选出一个具体卡点，并写出下一次检查动作。", feedback: "复盘把错题变成下一次的提醒。", choices: ["审题漏条件", "计算不稳定", "表达不清楚", "没有检验"]),
        LearningActivity(id: "act-j-equation-model", title: "门票方程模型", mode: .transfer, prompt: "成人票 30 元，学生票 18 元，一共 20 人花了 480 元。设一个未知数并写出方程。", lessonID: "j-equation2", stage: .junior, capabilities: [.modeling, .reasoning], minutes: 4, successCriteria: "能说明未知数含义，并写出人数关系和金额关系。", feedback: "你把文字条件压缩成了可求解的方程模型。"),
        LearningActivity(id: "act-j-function-taxi", title: "打车费用函数", mode: .transfer, prompt: "起步价 12 元含 3 千米，超过后每千米 2.4 元。写出超过 3 千米后的费用关系。", lessonID: "j-linear", stage: .junior, capabilities: [.modeling, .reasoning], minutes: 5, successCriteria: "能区分固定费用和变化费用，并写出一次函数关系。", feedback: "你抓住了函数中的固定量和变化量。"),
        LearningActivity(id: "act-j-proof-explain", title: "证明依据复述", mode: .reflect, prompt: "选择一个几何结论，说出能支持它的一个判定或性质。", lessonID: "j-proof", stage: .junior, capabilities: [.reasoning, .expression], minutes: 3, successCriteria: "能把结论和依据连成一句完整表达。", feedback: "证明能力的核心是让每一步都有依据。", choices: ["全等判定", "平行线性质", "相似判定", "圆周角性质"]),
        LearningActivity(id: "act-j-data-survey", title: "班级数据调查", mode: .transfer, prompt: "要了解班级一周运动时间，用平均数、中位数还是统计图说明更清楚？给出选择理由。", lessonID: "j-data", stage: .junior, capabilities: [.reasoning, .expression], minutes: 4, successCriteria: "能说明数据特征和表达方式之间的关系。", feedback: "你在选择数学工具，而不是机械计算。"),
        LearningActivity(id: "act-j-probability-experiment", title: "概率实验设计", mode: .transfer, prompt: "设计 20 次摸球实验，估计摸到红球的概率。说明记录方式。", lessonID: "j-probability", stage: .junior, capabilities: [.reasoning, .modeling], minutes: 4, successCriteria: "能说清样本空间、次数和频率记录。", feedback: "你把概率从答案变成了可观察的实验。"),
        LearningActivity(id: "act-j-reflect-strategy", title: "压轴题复盘句", mode: .reflect, prompt: "回想一道综合题，写下第一步为什么这样做。", lessonID: "j-challenge-real", stage: .junior, capabilities: [.focusReflection, .expression], minutes: 2, successCriteria: "能指出入口条件，例如变量、图形性质或数据关系。", feedback: "复盘第一步能帮助你下次更快进入题目。", choices: ["先设未知数", "先画图", "先找不变量", "先列数据表"])
    ]

    static func activities(for capability: Capability, stage: Stage) -> [LearningActivity] {
        learningActivities.filter { $0.stage == stage && $0.capabilities.contains(capability) }
    }

    static func activities(for stage: Stage) -> [LearningActivity] {
        learningActivities.filter { $0.stage == stage }
    }
```

- [ ] **Step 6: Preserve capabilities when rebuilding lessons**

In `MathContent.lessons`, update the returned `Lesson` initializer so it carries `lesson.capabilities`:

```swift
        return Lesson(id: lesson.id, title: lesson.title, ability: lesson.ability, subject: lesson.subject, stage: lesson.stage, minutes: lesson.minutes, summary: lesson.summary, questions: questions, capabilities: lesson.capabilities)
```

- [ ] **Step 7: Run the content test and commit**

Run:

```bash
scripts/test_question_bank.sh
git diff --check
```

Expected: both commands pass.

Commit:

```bash
git add MathTop/Models/LearningModels.swift MathTop/Content/MathContent.swift scripts/test_question_bank.swift
git commit -m "feat: add capability learning content"
```

---

### Task 2: Store Persistence, Study Sessions, And Streaks

**Files:**
- Modify: `MathTop/Store/LearningStore.swift`
- Create: `scripts/test_learning_system.swift`
- Create: `scripts/test_learning_system.sh`

**Interfaces:**
- Consumes: `LearningActivity`, `LearningActivityEvent`, `StudySession`, `Attempt`, `ReviewScheduler`.
- Produces: `LearningStore.activityEvents: [LearningActivityEvent]`.
- Produces: `LearningStore.studySessions: [StudySession]`.
- Produces: `LearningStore.streak: Int`, `LearningStore.lastStudyDate: Date?`.
- Produces: `LearningStore.completedSessionsCount: Int`, `LearningStore.reflectionCount: Int`.
- Produces: `LearningStore.init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init, calendar: Calendar = .current)`.
- Produces: `LearningStore.upsertStudySession(_ session: StudySession)`.
- Produces: `LearningStore.session(on date: Date = Date(), stage: Stage, calendar: Calendar = .current) -> StudySession?`.
- Produces: `LearningStore.completeActivity(_ activity: LearningActivity, in session: StudySession, score: Double = 1, note: String? = nil)`.

- [ ] **Step 1: Write the failing store tests**

Create `scripts/test_learning_system.swift`:

```swift
import Foundation

@main
struct LearningSystemRegressionTests {
    static func main() throws {
        try testStorePersistsSessionsEventsAndStreaks()
        print("PASS: learning system regression tests")
    }

    private static func testStorePersistsSessionsEventsAndStreaks() throws {
        let suiteName = "MathTopLearningSystemTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create isolated defaults")
        }
        defaults.removePersistentDomain(forName: suiteName)

        var now = fixedDate(2026, 9, 10)
        let calendar = fixedCalendar()
        let activity = LearningActivity(
            id: "act-test-transfer",
            title: "测试迁移",
            mode: .transfer,
            prompt: "写出数量关系",
            lessonID: "p-percent",
            stage: .primary,
            capabilities: [.modeling],
            minutes: 4,
            successCriteria: "写出关系式",
            feedback: "完成建模"
        )
        let session = StudySession(id: "study-20260910-小学", date: now, stage: .primary, activities: [activity], completedActivityIDs: [])
        let store = LearningStore(defaults: defaults, now: { now }, calendar: calendar)

        precondition(store.activityEvents.isEmpty, "Fresh store should not have activity events")
        precondition(store.studySessions.isEmpty, "Fresh store should not have study sessions")
        store.upsertStudySession(session)
        store.completeActivity(activity, in: session, score: 0.8, note: "先找变量")
        store.completeActivity(activity, in: session, score: 0.1, note: "重复打开不应重复计数")

        precondition(store.activityEvents.count == 1, "Completing an activity records one event")
        precondition(store.activityEvents[0].score == 0.8, "Event score should persist")
        precondition(store.activityEvents[0].capabilities == [.modeling], "Event capabilities should persist")
        precondition(store.studySessions.first?.isCompleted == true, "Session should be complete after its only activity")
        precondition(store.streak == 1, "First study day starts a streak")

        let reloaded = LearningStore(defaults: defaults, now: { now }, calendar: calendar)
        precondition(reloaded.activityEvents.count == 1, "Events should reload from defaults")
        precondition(reloaded.studySessions.first?.isCompleted == true, "Sessions should reload from defaults")
        precondition(reloaded.streak == 1, "Streak should reload from defaults")
        precondition(reloaded.session(on: now, stage: .primary, calendar: calendar)?.id == session.id, "Store should find today's session")

        now = fixedDate(2026, 9, 11)
        let nextActivity = LearningActivity(
            id: "act-test-reflect",
            title: "测试复盘",
            mode: .reflect,
            prompt: "选择错因",
            lessonID: nil,
            stage: .primary,
            capabilities: [.focusReflection],
            minutes: 2,
            successCriteria: "选出错因",
            feedback: "完成复盘"
        )
        let nextSession = StudySession(id: "study-20260911-小学", date: now, stage: .primary, activities: [nextActivity], completedActivityIDs: [])
        reloaded.completeActivity(nextActivity, in: nextSession)
        precondition(reloaded.streak == 2, "Consecutive days should increment streak")
        precondition(reloaded.reflectionCount == 1, "Reflection count should include reflect events")

        now = fixedDate(2026, 9, 14)
        let gapActivity = LearningActivity(
            id: "act-test-focus",
            title: "测试专注",
            mode: .focus,
            prompt: "专注练习",
            lessonID: nil,
            stage: .primary,
            capabilities: [.focusReflection],
            minutes: 3,
            successCriteria: "完成三分钟",
            feedback: "完成专注"
        )
        let gapSession = StudySession(id: "study-20260914-小学", date: now, stage: .primary, activities: [gapActivity], completedActivityIDs: [])
        reloaded.completeActivity(gapActivity, in: gapSession)
        precondition(reloaded.streak == 1, "A date gap resets streak to one")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func fixedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        return calendar
    }

    private static func fixedDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = fixedCalendar()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 9
        return components.date!
    }
}
```

Create `scripts/test_learning_system.sh`:

```bash
#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/mathtop-learning-system.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

xcrun --sdk macosx swiftc -module-cache-path "$test_dir/cache" \
    "$project_dir/MathTop/Models/LearningModels.swift" \
    "$project_dir/MathTop/Content/MathContent.swift" \
    "$project_dir/MathTop/Services/ReviewScheduler.swift" \
    "$project_dir/MathTop/Services/GrowthSummaryService.swift" \
    "$project_dir/MathTop/Services/DailyPlanService.swift" \
    "$project_dir/MathTop/Store/LearningStore.swift" \
    "$project_dir/scripts/test_learning_system.swift" \
    -o "$test_dir/test-learning-system"
"$test_dir/test-learning-system"
```

- [ ] **Step 2: Run the learning-system test to verify it fails**

Run:

```bash
chmod +x scripts/test_learning_system.sh
scripts/test_learning_system.sh
```

Expected: FAIL with compiler errors for the new `LearningStore` initializer, session properties, and completion methods.

- [ ] **Step 3: Implement store persistence**

Replace `MathTop/Store/LearningStore.swift` with:

```swift
import Foundation
import SwiftUI

final class LearningStore: ObservableObject {
    @Published private(set) var completedLessonIDs: Set<String> = []
    @Published private(set) var attempts: [Attempt] = []
    @Published private(set) var activityEvents: [LearningActivityEvent] = []
    @Published private(set) var studySessions: [StudySession] = []
    @Published private(set) var streak: Int = 0
    @Published private(set) var lastStudyDate: Date?

    var incorrectAttempts: [Attempt] { attempts.filter { !$0.correct } }
    var dueReviewCount: Int { attempts.filter { ReviewScheduler.isDue($0, now: now(), calendar: calendar) }.count }
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
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
scripts/test_learning_system.sh
scripts/test_question_bank.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/Store/LearningStore.swift scripts/test_learning_system.swift scripts/test_learning_system.sh
git commit -m "feat: persist study sessions"
```

---

### Task 3: Capability Growth Summary Calculation

**Files:**
- Modify: `MathTop/Services/GrowthSummaryService.swift`
- Modify: `scripts/test_learning_system.swift`

**Interfaces:**
- Consumes: `LearningStore.completedLessonIDs`, `attempts`, `incorrectAttempts`, `activityEvents`, `completedSessionsCount`, `reflectionCount`, `streak`.
- Produces: `CapabilityGrowthItem`.
- Produces: expanded `GrowthSummary` with `capabilitySnapshots`, `topCapability`, `weakCapability`, `streak`, `sessions`, `reflections`, `sevenDayActivityCounts`, and `nextStep`.
- Produces: `GrowthSummaryService.makeCapabilitySnapshots(events:attempts:lessons:now:calendar:)`.
- Produces: `GrowthSummaryService.sevenDayActivityCounts(events:now:calendar:)`.

- [ ] **Step 1: Add failing growth tests**

In `scripts/test_learning_system.swift`, update `main()`:

```swift
        try testStorePersistsSessionsEventsAndStreaks()
        try testGrowthSummaryUsesRecentCapabilityEvents()
        try testEmptyGrowthSummaryIsActionable()
```

Add these functions below the store test:

```swift
    private static func testGrowthSummaryUsesRecentCapabilityEvents() throws {
        let calendar = fixedCalendar()
        let now = fixedDate(2026, 9, 10)
        let oldDate = calendar.date(byAdding: .day, value: -40, to: now)!
        let lessons = [
            Lesson(id: "p-percent", title: "百分数", ability: "解决问题", subject: .math, stage: .primary, minutes: 8, summary: "折扣", questions: [], capabilities: [.modeling]),
            Lesson(id: "p-four", title: "四则运算", ability: "数与运算", subject: .math, stage: .primary, minutes: 8, summary: "计算", questions: [], capabilities: [.numberSense])
        ]
        let events = [
            LearningActivityEvent(id: UUID(), activityID: "transfer", sessionID: "s1", lessonID: "p-percent", mode: .transfer, capabilities: [.modeling], score: 1, note: nil, date: now),
            LearningActivityEvent(id: UUID(), activityID: "reflect", sessionID: "s1", lessonID: nil, mode: .reflect, capabilities: [.expression], score: 1, note: "讲清关系", date: now),
            LearningActivityEvent(id: UUID(), activityID: "old", sessionID: "s0", lessonID: "p-four", mode: .practice, capabilities: [.numberSense], score: 1, note: nil, date: oldDate)
        ]
        let attempts = [
            Attempt(id: UUID(), questionID: "q1", lessonID: "p-percent", correct: false, date: now)
        ]

        let snapshots = GrowthSummaryService.makeCapabilitySnapshots(events: events, attempts: attempts, lessons: lessons, now: now, calendar: calendar)
        precondition(snapshots.count == Capability.allCases.count, "Need one snapshot per capability")
        let modeling = snapshots.first { $0.capability == .modeling }!
        let numberSense = snapshots.first { $0.capability == .numberSense }!
        precondition(modeling.practiceCount == 2, "Modeling should count transfer plus related attempt")
        precondition(modeling.mastery > 0, "Recent transfer should increase modeling mastery")
        precondition(numberSense.practiceCount == 0, "Events older than 30 days should not affect current snapshots")
    }

    private static func testEmptyGrowthSummaryIsActionable() throws {
        let suiteName = "MathTopGrowthEmptyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = LearningStore(defaults: defaults, now: { fixedDate(2026, 9, 10) }, calendar: fixedCalendar())

        let summary = GrowthSummaryService.make(store: store, now: fixedDate(2026, 9, 10), calendar: fixedCalendar())
        precondition(summary.capabilitySnapshots.count == Capability.allCases.count, "Empty store still needs five capability snapshots")
        precondition(summary.nextStep == "先完成今日任务包，用一道题建立学习记录。", "Empty summary needs a concrete first action")
        precondition(summary.sevenDayActivityCounts.count == 7, "Growth summary needs seven trend points")

        defaults.removePersistentDomain(forName: suiteName)
    }
```

- [ ] **Step 2: Run the learning-system test to verify it fails**

Run:

```bash
scripts/test_learning_system.sh
```

Expected: FAIL with compiler errors for missing growth summary fields and methods.

- [ ] **Step 3: Implement growth summary calculation**

Replace `MathTop/Services/GrowthSummaryService.swift` with:

```swift
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
        let weak = snapshots.sorted { lhs, rhs in
            if lhs.mastery == rhs.mastery { return lhs.practiceCount < rhs.practiceCount }
            return lhs.mastery < rhs.mastery
        }.first.map { item(for: $0, weak: true) }

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
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
scripts/test_learning_system.sh
scripts/test_question_bank.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/Services/GrowthSummaryService.swift scripts/test_learning_system.swift
git commit -m "feat: calculate capability growth"
```

---

### Task 4: Daily Study Session Scheduling

**Files:**
- Modify: `MathTop/Services/DailyPlanService.swift`
- Modify: `scripts/test_learning_system.swift`

**Interfaces:**
- Consumes: `LearningStore`, `MathContent.lessons(for:)`, `MathContent.learningActivities`, `GrowthSummaryService.make`, `ReviewScheduler.isDue`.
- Produces: `DailyPlan.session: StudySession`.
- Produces: `DailyPlan.primary: Lesson`.
- Produces: `DailyPlan.next: Lesson?`.
- Produces: `DailyPlan.dueReviewCount: Int`.
- Produces: `DailyPlan.weakCapability: Capability?`.
- Produces: `DailyPlan.estimatedMinutes: Int`.
- Produces: overload `DailyPlanService.makePlan(stage:store:now:calendar:lessons:activities:)` for deterministic tests.

- [ ] **Step 1: Add failing daily plan tests**

In `scripts/test_learning_system.swift`, update `main()`:

```swift
        try testStorePersistsSessionsEventsAndStreaks()
        try testGrowthSummaryUsesRecentCapabilityEvents()
        try testEmptyGrowthSummaryIsActionable()
        try testDailyPlanBuildsCompleteLearningLoop()
        try testDailyPlanPrioritizesDueReview()
```

Add these functions:

```swift
    private static func testDailyPlanBuildsCompleteLearningLoop() throws {
        let suiteName = "MathTopDailyPlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let now = fixedDate(2026, 9, 10)
        let store = LearningStore(defaults: defaults, now: { now }, calendar: fixedCalendar())

        let plan = DailyPlanService.makePlan(stage: .primary, store: store, now: now, calendar: fixedCalendar())
        precondition(plan.session.activities.count == 4, "Daily plan should have understand, practice, transfer, and reflection")
        precondition(plan.session.activities.map(\.mode).contains(.understand), "Daily plan missing understand activity")
        precondition(plan.session.activities.map(\.mode).contains(.practice), "Daily plan missing practice activity")
        precondition(plan.session.activities.map(\.mode).contains(.transfer), "Daily plan missing transfer activity")
        precondition(plan.session.activities.map(\.mode).contains(.reflect), "Daily plan missing reflection activity")
        precondition((10...15).contains(plan.estimatedMinutes), "Daily plan should last 10-15 minutes")
        precondition(plan.primary.stage == .primary, "Primary plan should pick primary lesson")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static func testDailyPlanPrioritizesDueReview() throws {
        let suiteName = "MathTopDueReviewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var now = fixedDate(2026, 9, 1)
        let calendar = fixedCalendar()
        let store = LearningStore(defaults: defaults, now: { now }, calendar: calendar)
        store.recordAttempt(questionID: "p-percent-1", lessonID: "p-percent", correct: false)

        now = fixedDate(2026, 9, 10)
        let plan = DailyPlanService.makePlan(stage: .primary, store: store, now: now, calendar: calendar)
        precondition(plan.primary.id == "p-percent", "Due incorrect attempts should drive the primary lesson")
        precondition(plan.dueReviewCount == 1, "Plan should expose due review count")
        precondition(plan.session.activities.contains { $0.capabilities.contains(.modeling) }, "Plan should include modeling work for p-percent")

        defaults.removePersistentDomain(forName: suiteName)
    }
```

- [ ] **Step 2: Run the learning-system test to verify it fails**

Run:

```bash
scripts/test_learning_system.sh
```

Expected: FAIL because `DailyPlan` does not expose `session`, `dueReviewCount`, `weakCapability`, and `estimatedMinutes`.

- [ ] **Step 3: Implement session-based daily planning**

Replace `MathTop/Services/DailyPlanService.swift` with:

```swift
import Foundation

struct DailyPlan {
    let session: StudySession
    let primary: Lesson
    let next: Lesson?
    let stage: Stage
    let dueReviewCount: Int
    let weakCapability: Capability?

    var estimatedMinutes: Int { session.estimatedMinutes }
}

enum DailyPlanService {
    static func makePlan(stage: Stage, store: LearningStore, now: Date = Date(), calendar: Calendar = .current) -> DailyPlan {
        makePlan(stage: stage, store: store, now: now, calendar: calendar, lessons: MathContent.lessons(for: stage), activities: MathContent.learningActivities)
    }

    static func makePlan(stage: Stage, store: LearningStore, now: Date = Date(), calendar: Calendar = .current, lessons: [Lesson], activities: [LearningActivity]) -> DailyPlan {
        if let existing = store.session(on: now, stage: stage, calendar: calendar), let primary = primaryLesson(for: existing, lessons: lessons, stage: stage) {
            return DailyPlan(session: existing, primary: primary, next: nextLesson(after: primary, in: lessons, store: store), stage: stage, dueReviewCount: dueAttempts(in: store, lessons: lessons, now: now, calendar: calendar).count, weakCapability: GrowthSummaryService.make(store: store, now: now, calendar: calendar).weakCapability?.capability)
        }

        let fallback = Lesson(id: "empty-\(stage.rawValue)", title: "准备你的第一课", ability: "基础能力", subject: .math, stage: stage, minutes: 5, summary: "题库正在准备，先从基础概念开始。", questions: [], capabilities: [.numberSense, .focusReflection])
        let candidateLessons = lessons.isEmpty ? [fallback] : lessons
        let due = dueAttempts(in: store, lessons: candidateLessons, now: now, calendar: calendar)
        let weakCapability = GrowthSummaryService.make(store: store, now: now, calendar: calendar).weakCapability?.capability
        let primary = lessonForDueAttempt(due.first, lessons: candidateLessons)
            ?? lessonForCapability(weakCapability, lessons: candidateLessons, store: store)
            ?? candidateLessons.first(where: { !store.completedLessonIDs.contains($0.id) })
            ?? candidateLessons[0]
        let transfer = transferActivity(for: primary, weakCapability: weakCapability, stage: stage, activities: activities)
        let session = StudySession(
            id: sessionID(for: stage, date: now, calendar: calendar),
            date: now,
            stage: stage,
            activities: [
                understandActivity(for: primary),
                practiceActivity(for: primary),
                transfer,
                reflectionActivity(for: primary)
            ],
            completedActivityIDs: []
        )
        return DailyPlan(session: session, primary: primary, next: nextLesson(after: primary, in: candidateLessons, store: store), stage: stage, dueReviewCount: due.count, weakCapability: weakCapability)
    }

    private static func dueAttempts(in store: LearningStore, lessons: [Lesson], now: Date, calendar: Calendar) -> [Attempt] {
        let lessonIDs = Set(lessons.map(\.id))
        return store.attempts.filter { lessonIDs.contains($0.lessonID) && ReviewScheduler.isDue($0, now: now, calendar: calendar) }
    }

    private static func lessonForDueAttempt(_ attempt: Attempt?, lessons: [Lesson]) -> Lesson? {
        guard let attempt else { return nil }
        return lessons.first { $0.id == attempt.lessonID }
    }

    private static func lessonForCapability(_ capability: Capability?, lessons: [Lesson], store: LearningStore) -> Lesson? {
        guard let capability else { return nil }
        return lessons.first { lesson in
            lesson.capabilities.contains(capability) && !store.completedLessonIDs.contains(lesson.id)
        } ?? lessons.first { $0.capabilities.contains(capability) }
    }

    private static func primaryLesson(for session: StudySession, lessons: [Lesson], stage: Stage) -> Lesson? {
        if let lessonID = session.activities.compactMap(\.lessonID).first {
            return lessons.first { $0.id == lessonID }
        }
        return lessons.first { $0.stage == stage }
    }

    private static func nextLesson(after lesson: Lesson, in lessons: [Lesson], store: LearningStore) -> Lesson? {
        if let nextIncomplete = lessons.first(where: { $0.id != lesson.id && !store.completedLessonIDs.contains($0.id) }) {
            return nextIncomplete
        }
        guard let index = lessons.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        let nextIndex = index + 1
        return nextIndex < lessons.count ? lessons[nextIndex] : nil
    }

    private static func understandActivity(for lesson: Lesson) -> LearningActivity {
        LearningActivity(id: "understand-\(lesson.id)", title: "看懂 \(lesson.title)", mode: .understand, prompt: lesson.summary, lessonID: lesson.id, stage: lesson.stage, capabilities: lesson.capabilities, minutes: 2, successCriteria: "能说出本课要解决的核心关系。", feedback: "先看懂目标，再进入练习。")
    }

    private static func practiceActivity(for lesson: Lesson) -> LearningActivity {
        let ids = Array(lesson.questions.prefix(3).map(\.id))
        return LearningActivity(id: "practice-\(lesson.id)", title: "练习 \(lesson.title)", mode: .practice, prompt: lesson.questions.isEmpty ? "用自己的话复述本课方法，再完成一道同类题。" : "完成 2 到 3 道题，答题后看解析。", lessonID: lesson.id, questionIDs: ids, stage: lesson.stage, capabilities: lesson.capabilities, minutes: 4, successCriteria: "完成练习并查看关键解析。", feedback: "练习记录会进入能力成长。")
    }

    private static func transferActivity(for lesson: Lesson, weakCapability: Capability?, stage: Stage, activities: [LearningActivity]) -> LearningActivity {
        let stageActivities = activities.filter { $0.stage == stage && $0.mode == .transfer }
        if let weakCapability, let match = stageActivities.first(where: { $0.capabilities.contains(weakCapability) }) {
            return match
        }
        if let match = stageActivities.first(where: { activity in
            activity.lessonID == lesson.id || !Set(activity.capabilities).isDisjoint(with: lesson.capabilities)
        }) {
            return match
        }
        return LearningActivity(id: "transfer-\(lesson.id)", title: "迁移 \(lesson.title)", mode: .transfer, prompt: "把 \(lesson.title) 放进一个生活情境，写出数量关系或判断依据。", lessonID: lesson.id, stage: stage, capabilities: lesson.capabilities, minutes: 4, successCriteria: "能说明情境、关系和结论。", feedback: "你完成了一次从知识点到真实问题的迁移。")
    }

    private static func reflectionActivity(for lesson: Lesson) -> LearningActivity {
        LearningActivity(id: "reflect-\(lesson.id)", title: "复盘 \(lesson.title)", mode: .reflect, prompt: "今天最卡的是审题、计算、表达还是验证？写下一句下次提醒。", lessonID: lesson.id, stage: lesson.stage, capabilities: [.expression, .focusReflection], minutes: 2, successCriteria: "能选出一个卡点并写出下次动作。", feedback: "复盘让下一次练习更有方向。", choices: ["审题", "计算", "表达", "验证"])
    }

    private static func sessionID(for stage: Stage, date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "study-%04d%02d%02d-%@", components.year ?? 0, components.month ?? 0, components.day ?? 0, stage.rawValue)
    }
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
scripts/test_learning_system.sh
scripts/test_question_bank.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/Services/DailyPlanService.swift scripts/test_learning_system.swift
git commit -m "feat: schedule daily study sessions"
```

---

### Task 5: Practice Flow Records Capability Activity Progress

**Files:**
- Modify: `MathTop/App/MathTopApp.swift`

**Interfaces:**
- Consumes: `LearningActivity.mode == .practice`, `StudySession`, `LearningStore.completeActivity`.
- Produces: `PracticeView.init(lesson:session:activity:onComplete:)` with `session` and `activity` optional so existing lesson entry points still work.
- Produces: practice score based on correct answers divided by answered questions.

- [ ] **Step 1: Run a compile check before editing UI**

Run:

```bash
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds before UI changes. If it fails because the scheme is missing after local project drift, run `xcodegen generate`, then run the same build command again.

- [ ] **Step 2: Update `PracticeView` state and initializer**

In `MathTop/App/MathTopApp.swift`, change the start of `PracticeView` to:

```swift
struct PracticeView: View {
    let lesson: Lesson
    let session: StudySession?
    let activity: LearningActivity?
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var answer = ""
    @State private var submitted = false
    @State private var answeredCount = 0
    @State private var correctCount = 0
    private var question: Question? { lesson.questions.indices.contains(step) ? lesson.questions[step] : nil }
    let onComplete: () -> Void

    init(lesson: Lesson, session: StudySession? = nil, activity: LearningActivity? = nil, onComplete: @escaping () -> Void) {
        self.lesson = lesson
        self.session = session
        self.activity = activity
        self.onComplete = onComplete
    }
```

- [ ] **Step 3: Record answer counts when submitting**

Inside the `Button` action in `PracticeView`, replace the first submit branch with:

```swift
                    if !submitted {
                        let isCorrect = answer == question.answer
                        store.recordAttempt(questionID: question.id, lessonID: lesson.id, correct: isCorrect)
                        answeredCount += 1
                        if isCorrect { correctCount += 1 }
                        submitted = true
                    } else {
                        answer = ""
                        submitted = false
                        step += 1
                    }
```

- [ ] **Step 4: Record the practice activity when the lesson finishes**

Replace the completion branch:

```swift
                } else {
                    onComplete()
                    dismiss()
                }
```

with:

```swift
                } else {
                    if let session, let activity {
                        let score = answeredCount == 0 ? 1 : Double(correctCount) / Double(answeredCount)
                        store.completeActivity(activity, in: session, score: score, note: "完成 \(answeredCount) 题，答对 \(correctCount) 题")
                    }
                    onComplete()
                    dismiss()
                }
```

- [ ] **Step 5: Run build checks and commit**

Run:

```bash
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
scripts/test_learning_system.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/App/MathTopApp.swift
git commit -m "feat: record practice capability progress"
```

---

### Task 6: Home Daily Task Panel And Learning Activity Scenes

**Files:**
- Modify: `MathTop/App/MathTopApp.swift`

**Interfaces:**
- Consumes: `DailyPlan.session`, `LearningActivity`, `LearningMode`, `LearningStore.upsertStudySession`, `LearningStore.completeActivity`.
- Produces: `DailyTaskPanel`.
- Produces: `ActivityRunnerView`.
- Produces: `UnderstandActivityView`, `TransferChallengeView`, `ExplainBackView`, `FocusSprintView`, `ReflectionView`.
- Produces: Home progress driven by `StudySession.completedActivityIDs`.

- [ ] **Step 1: Update Home state to open individual activities**

Replace `HomeView` state:

```swift
    @State private var showPractice = false
    @AppStorage("todayCompleted") private var todayCompleted = false
```

with:

```swift
    @State private var selectedActivity: LearningActivity?
```

- [ ] **Step 2: Replace the hero-only center of Home**

In `HomeView.body`, replace the `HeroCard`, hard-coded "今日能力组合", and sheet with:

```swift
                    let plan = dailyPlan
                    DailyTaskPanel(plan: plan, store: store) { activity in
                        store.upsertStudySession(plan.session)
                        selectedActivity = activity
                    }
                    Text("今日能力组合").font(.title3.bold()).foregroundStyle(ink)
                    HStack(spacing: 12) {
                        ForEach(plan.primary.capabilities.prefix(2), id: \.self) { capability in
                            SkillCard(icon: capability.systemImage, title: capability.title, subtitle: "今日任务关联", color: capability == .modeling ? coral : mint, progress: GrowthSummaryService.make(store: store).capabilitySnapshots.first { $0.capability == capability }?.mastery ?? 0)
                        }
                    }
```

Replace the `.sheet` modifier with:

```swift
            .sheet(item: $selectedActivity) { activity in
                ActivityRunnerView(activity: activity, session: dailyPlan.session, primary: dailyPlan.primary) {
                    selectedActivity = nil
                }
                .environmentObject(store)
            }
```

- [ ] **Step 3: Add `DailyTaskPanel` below `HeroCard`**

Add this struct below `HeroCard`:

```swift
struct DailyTaskPanel: View {
    let plan: DailyPlan
    @ObservedObject var store: LearningStore
    let onStart: (LearningActivity) -> Void

    private var completedIDs: Set<String> {
        store.session(on: plan.session.date, stage: plan.stage)?.completedActivityIDs ?? plan.session.completedActivityIDs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日任务包").font(.caption.bold()).foregroundStyle(coral)
                    Text(plan.primary.title).font(.title2.bold()).foregroundStyle(ink)
                }
                Spacer()
                Text("\(plan.estimatedMinutes) 分钟").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Text(plan.primary.summary).font(.subheadline).foregroundStyle(ink.opacity(0.72)).fixedSize(horizontal: false, vertical: true)
            if plan.dueReviewCount > 0 {
                Label("\(plan.dueReviewCount) 个错题到期复习", systemImage: "clock.badge.exclamationmark")
                    .font(.caption.bold())
                    .foregroundStyle(coral)
            }
            ForEach(plan.session.activities) { activity in
                Button { onStart(activity) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: completedIDs.contains(activity.id) ? "checkmark.circle.fill" : activity.modeIcon)
                            .foregroundStyle(completedIDs.contains(activity.id) ? .green : coral)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(activity.mode.title) · \(activity.title)").font(.headline).foregroundStyle(ink)
                            Text(activity.successCriteria).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Spacer()
                        Text("\(activity.minutes)′").font(.caption.bold()).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(18)
        .background(LinearGradient(colors: [Color(red: 1, green: 0.90, blue: 0.72), Color(red: 1, green: 0.76, blue: 0.58)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

extension LearningActivity {
    var modeIcon: String {
        switch mode {
        case .understand: return "eye"
        case .practice: return "pencil.and.list.clipboard"
        case .transfer: return "arrow.triangle.branch"
        case .reflect: return "text.bubble"
        case .focus: return "timer"
        }
    }
}
```

- [ ] **Step 4: Add the activity runner**

Add this struct below `DailyTaskPanel`:

```swift
struct ActivityRunnerView: View {
    let activity: LearningActivity
    let session: StudySession
    let primary: Lesson
    let onClose: () -> Void

    @EnvironmentObject private var store: LearningStore

    var body: some View {
        Group {
            switch activity.mode {
            case .understand:
                UnderstandActivityView(activity: activity, session: session, onClose: onClose)
            case .practice:
                PracticeView(lesson: primary, session: session, activity: activity) {
                    store.markLessonCompleted(primary)
                    onClose()
                }
            case .transfer:
                TransferChallengeView(activity: activity, session: session, onClose: onClose)
            case .reflect:
                if activity.choices.isEmpty {
                    ReflectionView(activity: activity, session: session, onClose: onClose)
                } else {
                    ExplainBackView(activity: activity, session: session, onClose: onClose)
                }
            case .focus:
                FocusSprintView(activity: activity, session: session, onClose: onClose)
            }
        }
    }
}
```

- [ ] **Step 5: Add the five lightweight scenes**

Add these views below `ActivityRunnerView`:

```swift
struct UnderstandActivityView: View {
    let activity: LearningActivity
    let session: StudySession
    let onClose: () -> Void
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(activity.prompt).font(.title3).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Label(activity.successCriteria, systemImage: "target").foregroundStyle(coral)
                Spacer()
                Button { complete() } label: {
                    Label("我看懂了", systemImage: "checkmark.circle.fill").font(.headline).frame(maxWidth: .infinity).padding().background(ink).foregroundStyle(.white).clipShape(Capsule())
                }
            }
            .padding(24)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss(); onClose() } } }
        }
    }

    private func complete() {
        store.completeActivity(activity, in: session, score: 1, note: "完成理解")
        dismiss()
        onClose()
    }
}

struct TransferChallengeView: View {
    let activity: LearningActivity
    let session: StudySession
    let onClose: () -> Void
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(activity.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(activity.prompt).font(.body).foregroundStyle(ink.opacity(0.76)).fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $answer).frame(minHeight: 150).padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                Text(activity.successCriteria).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { complete() } label: {
                    Label("完成迁移", systemImage: "arrow.triangle.branch").font(.headline).frame(maxWidth: .infinity).padding().background(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : ink).foregroundStyle(.white).clipShape(Capsule())
                }
                .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(24)
            .background(Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss(); onClose() } } }
        }
    }

    private func complete() {
        store.completeActivity(activity, in: session, score: 1, note: answer)
        dismiss()
        onClose()
    }
}

struct ExplainBackView: View {
    let activity: LearningActivity
    let session: StudySession
    let onClose: () -> Void
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(activity.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(activity.prompt).foregroundStyle(.secondary)
                ForEach(activity.choices, id: \.self) { choice in
                    Button { selected = choice } label: {
                        HStack {
                            Text(choice).foregroundStyle(ink)
                            Spacer()
                            if selected == choice { Image(systemName: "checkmark.circle.fill").foregroundStyle(coral) }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Spacer()
                Button { complete() } label: {
                    Label("完成表达", systemImage: "text.bubble.fill").font(.headline).frame(maxWidth: .infinity).padding().background(selected.isEmpty ? Color.gray : ink).foregroundStyle(.white).clipShape(Capsule())
                }
                .disabled(selected.isEmpty)
            }
            .padding(24)
            .background(Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss(); onClose() } } }
        }
    }

    private func complete() {
        store.completeActivity(activity, in: session, score: 1, note: selected)
        dismiss()
        onClose()
    }
}

struct FocusSprintView: View {
    let activity: LearningActivity
    let session: StudySession
    let onClose: () -> Void
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var started = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "timer").font(.system(size: 60)).foregroundStyle(coral)
                Text(activity.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(activity.prompt).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text(started ? "保持审题、列式、检查三个动作。" : activity.successCriteria).font(.headline).foregroundStyle(ink)
                Spacer()
                Button { started ? complete() : (started = true) } label: {
                    Label(started ? "完成专注" : "开始专注", systemImage: started ? "checkmark.circle.fill" : "play.fill").font(.headline).frame(maxWidth: .infinity).padding().background(ink).foregroundStyle(.white).clipShape(Capsule())
                }
            }
            .padding(24)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss(); onClose() } } }
        }
    }

    private func complete() {
        store.completeActivity(activity, in: session, score: 1, note: "完成专注")
        dismiss()
        onClose()
    }
}

struct ReflectionView: View {
    let activity: LearningActivity
    let session: StudySession
    let onClose: () -> Void
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(activity.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(activity.prompt).foregroundStyle(.secondary)
                TextEditor(text: $note).frame(minHeight: 130).padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                Text(activity.feedback).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { complete() } label: {
                    Label("保存复盘", systemImage: "checkmark.seal.fill").font(.headline).frame(maxWidth: .infinity).padding().background(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : ink).foregroundStyle(.white).clipShape(Capsule())
                }
                .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(24)
            .background(Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss(); onClose() } } }
        }
    }

    private func complete() {
        store.completeActivity(activity, in: session, score: 1, note: note)
        dismiss()
        onClose()
    }
}
```

- [ ] **Step 6: Run build checks and commit**

Run:

```bash
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
scripts/test_learning_system.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/App/MathTopApp.swift
git commit -m "feat: add daily capability activities"
```

---

### Task 7: Capability Map Overview And Training Lists

**Files:**
- Modify: `MathTop/App/MathTopApp.swift`

**Interfaces:**
- Consumes: `GrowthSummaryService.make(store:)`, `MathContent.activities(for:stage:)`, `CapabilitySnapshot`.
- Produces: top five-dimension capability overview in `PathView`.
- Produces: `CapabilityTrainingView(capability:stage:)`.
- Preserves: existing lesson grouping and `SkillDetailView` navigation.

- [ ] **Step 1: Add capability overview section to `PathView`**

Inside `PathView`'s `List`, after the stage picker section, insert:

```swift
            let summary = GrowthSummaryService.make(store: store)
            Section("五维能力") {
                ForEach(summary.capabilitySnapshots) { snapshot in
                    NavigationLink { CapabilityTrainingView(capability: snapshot.capability, stage: stage) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: snapshot.capability.systemImage).foregroundStyle(coral).frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snapshot.capability.title).font(.headline)
                                Text("\(snapshot.practiceCount) 次有效练习 · \(snapshot.trend.title)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            ProgressView(value: snapshot.mastery).frame(width: 78).tint(coral)
                        }
                    }
                }
            }
```

- [ ] **Step 2: Add `CapabilityTrainingView`**

Add this struct below `PathView`:

```swift
struct CapabilityTrainingView: View {
    let capability: Capability
    let stage: Stage

    private var activities: [LearningActivity] { MathContent.activities(for: capability, stage: stage) }
    private var lessons: [Lesson] { MathContent.lessons(for: stage).filter { $0.capabilities.contains(capability) } }

    var body: some View {
        List {
            Section("能力训练") {
                if activities.isEmpty {
                    Text("今日任务包会自动安排 \(capability.title) 训练。").foregroundStyle(.secondary)
                } else {
                    ForEach(activities) { activity in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activity.title).font(.headline)
                            Text(activity.prompt).font(.caption).foregroundStyle(.secondary)
                            Label("\(activity.minutes) 分钟 · \(activity.mode.title)", systemImage: activity.modeIcon).font(.caption).foregroundStyle(coral)
                        }
                    }
                }
            }
            Section("关联知识点") {
                ForEach(lessons) { lesson in
                    NavigationLink { SkillDetailView(lesson: lesson) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title).font(.headline)
                            Text(lesson.summary).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(capability.title)
    }
}
```

- [ ] **Step 3: Update lesson rows to show capability tags**

In `PathView.row(_:)`, replace the subtitle text:

```swift
Text("\(lesson.minutes) 分钟 · \(lesson.title)").font(.caption).foregroundStyle(.secondary)
```

with:

```swift
Text("\(lesson.minutes) 分钟 · \(lesson.capabilities.map(\.shortTitle).joined(separator: " / "))").font(.caption).foregroundStyle(.secondary)
```

- [ ] **Step 4: Run build checks and commit**

Run:

```bash
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
scripts/test_learning_system.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/App/MathTopApp.swift
git commit -m "feat: show capability map overview"
```

---

### Task 8: Notebook Learning Tools And Growth UI

**Files:**
- Modify: `MathTop/App/MathTopApp.swift`

**Interfaces:**
- Consumes: `GrowthSummary`, `CapabilitySnapshot`, `LearningStore.streak`, `completedSessionsCount`, `reflectionCount`.
- Produces: notebook sections for knowledge points, wrong-question transformer, and learning tools.
- Produces: `EstimationToolView`, `UnitConversionTipsView`, `SolutionChecklistView`.
- Produces: expanded `ProfileView` stats and `GrowthSummaryView` capability summary.

- [ ] **Step 1: Replace `NotebookView` body**

Replace `NotebookView.body` with:

```swift
    var body: some View {
        NavigationStack {
            List {
                Section("知识点") {
                    NavigationLink { CurriculumListView(stage: .primary) } label: { HStack { Label("小学数学知识点", systemImage: "number.square"); Spacer(); Text("\(MathContent.lessons(for: .primary).count)").foregroundStyle(.secondary) } }
                    NavigationLink { CurriculumListView(stage: .junior) } label: { HStack { Label("初中数学知识点", systemImage: "function"); Spacer(); Text("\(MathContent.lessons(for: .junior).count)").foregroundStyle(.secondary) } }
                }
                Section("错题变身器") {
                    NavigationLink { ErrorBookView() } label: { HStack { Label("到期错题与复习", systemImage: "arrow.triangle.2.circlepath"); Spacer(); Text("\(store.incorrectAttempts.count)").foregroundStyle(.secondary) } }
                }
                Section("学习工具") {
                    NavigationLink { EstimationToolView() } label: { Label("估算器", systemImage: "plus.forwardslash.minus") }
                    NavigationLink { UnitConversionTipsView() } label: { Label("单位换算提示", systemImage: "ruler") }
                    NavigationLink { SolutionChecklistView() } label: { Label("解题步骤检查清单", systemImage: "checklist") }
                }
            }
            .navigationTitle("知识本")
        }
    }
```

- [ ] **Step 2: Add learning tool views**

Add these structs below `NotebookView`:

```swift
struct EstimationToolView: View {
    var body: some View {
        List {
            Section("估算三步") {
                Label("先看数量级：结果大约是几十、几百还是几千", systemImage: "1.circle")
                Label("把复杂数凑成整十、整百或常见分数", systemImage: "2.circle")
                Label("精算后用估算值检查是否离谱", systemImage: "3.circle")
            }
            Section("例子") {
                Text("48 × 25 可以看作 50 × 25，约 1250；精算 1200，量级合理。")
            }
        }
        .navigationTitle("估算器")
    }
}

struct UnitConversionTipsView: View {
    var body: some View {
        List {
            Section("常用关系") {
                row("长度", "1 米 = 10 分米 = 100 厘米")
                row("面积", "1 平方米 = 10000 平方厘米")
                row("体积", "1 立方米 = 1000 立方分米")
                row("时间", "1 小时 = 60 分钟，1 分钟 = 60 秒")
            }
            Section("检查动作") {
                Text("列式前先统一单位，写答案时补上单位。")
            }
        }
        .navigationTitle("单位换算")
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}

struct SolutionChecklistView: View {
    var body: some View {
        List {
            Section("做题前") {
                Label("圈出问题问什么", systemImage: "checkmark.circle")
                Label("标出已知条件和单位", systemImage: "checkmark.circle")
            }
            Section("做题中") {
                Label("写清变量或数量关系", systemImage: "checkmark.circle")
                Label("每一步计算保留依据", systemImage: "checkmark.circle")
            }
            Section("做题后") {
                Label("用估算、单位或代入检验答案", systemImage: "checkmark.circle")
                Label("错题记录一个下次提醒", systemImage: "checkmark.circle")
            }
        }
        .navigationTitle("解题检查")
    }
}
```

- [ ] **Step 3: Update `ProfileView` stats**

Inside `ProfileView.body`, define a local summary before the main stack:

```swift
            let summary = GrowthSummaryService.make(store: store)
```

Replace the stats `HStack` with:

```swift
                HStack(spacing: 12) {
                    stat("\(summary.streak)", "连续天数")
                    stat("\(summary.sessions)", "任务包")
                    stat("\(summary.reflections)", "复盘")
                }.padding(.top, 10)
```

Replace the bottom hint text with:

```swift
                Text(summary.nextStep).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
```

- [ ] **Step 4: Replace `GrowthSummaryView` body**

Replace `GrowthSummaryView.body` with:

```swift
    var body: some View {
        let summary = GrowthSummaryService.make(store: store)
        return List {
            Section("学习总览") {
                row("已解锁知识点", "\(summary.completed)/\(summary.total)")
                row("累计练习题", "\(summary.attempts)")
                row("待复习错题", "\(summary.incorrect)")
                row("连续学习", "\(summary.streak) 天")
                row("完成任务包", "\(summary.sessions)")
                row("复盘次数", "\(summary.reflections)")
            }
            Section("五维能力") {
                ForEach(summary.capabilitySnapshots) { snapshot in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(snapshot.capability.title, systemImage: snapshot.capability.systemImage)
                            Spacer()
                            Text(snapshot.trend.title).font(.caption.bold()).foregroundStyle(coral)
                        }
                        ProgressView(value: snapshot.mastery).tint(coral)
                        Text("\(snapshot.practiceCount) 次有效练习").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("最近 7 天") {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(summary.sevenDayActivityCounts.enumerated()), id: \.offset) { item in
                        Capsule()
                            .fill(coral.opacity(item.element == 0 ? 0.18 : 0.85))
                            .frame(width: 18, height: CGFloat(max(8, item.element * 12)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Text(summary.nextStep).font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("成长摘要")
    }
```

- [ ] **Step 5: Run build checks and commit**

Run:

```bash
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
scripts/test_learning_system.sh
git diff --check
```

Expected: all commands pass.

Commit:

```bash
git add MathTop/App/MathTopApp.swift
git commit -m "feat: enrich growth and notebook views"
```

---

### Task 9: Full Verification And Release Check

**Files:**
- Verify: all modified Swift, script, and docs files.
- Modify only if a verification command exposes a concrete compile or regression issue.

**Interfaces:**
- Consumes: all tasks above.
- Produces: verified working state with script tests, SwiftUI build, and whitespace checks passing.

- [ ] **Step 1: Run full automated verification**

Run:

```bash
scripts/test_question_bank.sh
scripts/test_learning_system.sh
git diff --check
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
```

Expected:

```text
PASS: catalog initialized
PASS: learning system regression tests
```

`git diff --check` exits with code 0. `xcodebuild` exits with code 0.

- [ ] **Step 2: Inspect the final diff for scope**

Run:

```bash
git status --short
git diff --stat
git diff -- MathTop/Models/LearningModels.swift MathTop/Store/LearningStore.swift MathTop/Services/GrowthSummaryService.swift MathTop/Services/DailyPlanService.swift MathTop/Content/MathContent.swift MathTop/App/MathTopApp.swift scripts/test_question_bank.swift scripts/test_learning_system.swift
```

Expected: the diff only contains capability-learning models, services, content, UI, and tests from this plan. Existing unrelated dirty files such as Xcode user data remain untouched.

- [ ] **Step 3: Manual simulator smoke test**

Run the app in Xcode or with the build product and verify these flows:

```text
新用户进入 今日 -> 今日任务包显示 4 个活动 -> 打开理解活动 -> 完成后活动打勾
今日 -> 打开练习活动 -> 答题完成 -> 首页、能力地图、成长摘要同步出现能力练习记录
今日 -> 打开迁移活动 -> 输入一句关系说明 -> 完成后成长摘要的五维能力计数增加
知识本 -> 估算器、单位换算提示、解题步骤检查清单均可进入
我的 -> 成长摘要显示连续天数、任务包、复盘次数、五维能力和最近 7 天趋势
能力地图 -> 点击任一能力 -> 进入能力训练列表 -> 仍可进入原知识点详情
```

- [ ] **Step 4: Commit final verification fixes if any were needed**

If Step 1 or Step 3 required a code correction, run:

```bash
scripts/test_question_bank.sh
scripts/test_learning_system.sh
git diff --check
xcodebuild -project MathTop.xcodeproj -scheme MathTop -destination 'generic/platform=iOS Simulator' build
git add MathTop scripts
git commit -m "fix: stabilize capability learning flow"
```

Expected: verification commands pass before the commit.

---

## Self-Review

- Spec coverage: Task 1 covers the five capability dimensions and activity content. Task 2 covers persistence, sessions, streaks, and legacy key compatibility. Task 3 covers 30-day growth, trends, weak capability, and next-step suggestions. Task 4 covers daily 10-15 minute scheduling. Tasks 5-8 cover Home, capability map, notebook, profile, and the new learning scenes. Task 9 covers automated and manual verification.
- Placeholder scan: the plan defines concrete file paths, signatures, code snippets, commands, expected failures, and expected passing checks.
- Type consistency: `Capability`, `LearningMode`, `LearningActivity`, `LearningActivityEvent`, `StudySession`, `CapabilitySnapshot`, `GrowthSummary`, `DailyPlan`, and every service/store method are named consistently across all tasks.

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

    /// 一句话说明这项能力在练什么，用于能力概览卡与知识点派生题。
    var blurb: String {
        switch self {
        case .numberSense: return "估算、心算与数的大小感觉"
        case .modeling: return "把生活情境写成数量关系"
        case .reasoning: return "找规律、讲依据、做验证"
        case .expression: return "把思路说清楚、写完整"
        case .focusReflection: return "短时专注与错因复盘"
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

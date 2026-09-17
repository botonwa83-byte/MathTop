import Foundation

// MARK: - 习题草稿
//
// 人工策展题统一用「选项数组 + 正确项下标」书写：
// 下标写出来就能一眼看出答案位置是否失衡，避免全套题答案都落在 A。

struct PracticeDraft {
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let explanation: String

    static func q(_ prompt: String, _ options: [String], _ answerIndex: Int, _ explanation: String) -> PracticeDraft {
        PracticeDraft(prompt: prompt, options: options, answerIndex: answerIndex, explanation: explanation)
    }
}

/// 人工策展题库：`小学` 与 `初中` 两份，按知识点 id 索引。
enum LessonPracticeBank {
    static var questions: [String: [PracticeDraft]] {
        PrimaryPracticeBank.questions
            .merging(JuniorPracticeBank.questions) { primary, _ in primary }
            .merging(SupplementPracticeBank.questions) { existing, supplement in existing + supplement }
    }
}

// MARK: - 习题工厂

/// 把「人工策展题」与「按知识点内容派生的巩固题」合成一个完整题组。
///
/// 规则：
/// 1. 人工策展题优先，且顺序不变（部分知识点策展题已超过 `questionsPerPoint`，全部保留）；
/// 2. 不足 `questionsPerPoint` 时，用该知识点自身的规则摘要、能力定位与学习方法补齐；
/// 3. 派生题绝不复用策展题 id，答案位置由 id 的稳定哈希决定，避免恒为 A。
enum LessonPracticeFactory {
    /// 每个知识点至少配备的题量。
    static let questionsPerPoint = 10
    /// 每批练习题量（练习页按批推进）。
    static let batchSize = 5

    static func questions(for lesson: Lesson, curated: [Question], peers: [Lesson]) -> [Question] {
        var result = curated
        var usedIDs = Set(result.map(\.id))
        var index = 1

        for draft in derivedDrafts(for: lesson, peers: peers) {
            guard result.count < questionsPerPoint else { break }
            var id = "\(lesson.id)-k\(index)"
            while usedIDs.contains(id) {
                index += 1
                id = "\(lesson.id)-k\(index)"
            }
            usedIDs.insert(id)
            index += 1
            result.append(makeQuestion(id: id, draft: draft))
        }
        return result.map(rotatingOptions)
    }

    /// 把选项顺序按题目 id 的稳定哈希旋转。
    /// 人工写题时正确项几乎都写在第一个，这里统一打散，避免整套题的答案都落在 A。
    /// 使用自实现的 FNV-1a 而非 `hashValue`，保证每次启动得到同样的顺序。
    static func rotatingOptions(_ question: Question) -> Question {
        guard question.choices.count > 1 else { return question }
        let count = question.choices.count
        let offset = Int(stableHash(question.id) % UInt64(count))
        guard offset != 0 else { return question }
        let choices = question.choices
        let ordered = Array(choices[offset...] + choices[..<offset])
        return Question(
            id: question.id,
            prompt: question.prompt,
            kind: question.kind,
            choices: ordered,
            answer: question.answer,
            explanation: question.explanation,
            source: question.source
        )
    }

    /// 按批切分题组，`batch` 从 0 开始。
    static func batch(_ questions: [Question], index: Int) -> [Question] {
        guard index >= 0 else { return [] }
        return Array(questions.dropFirst(index * batchSize).prefix(batchSize))
    }

    static func batchCount(for questions: [Question]) -> Int {
        max(1, Int(ceil(Double(questions.count) / Double(batchSize))))
    }

    static func makeQuestion(id: String, draft: PracticeDraft) -> Question {
        let choices = draft.options.map { QuestionChoice(id: $0, text: $0) }
        let safeIndex = draft.options.indices.contains(draft.answerIndex) ? draft.answerIndex : 0
        return Question(
            id: id,
            prompt: draft.prompt,
            kind: .choice,
            choices: choices,
            answer: draft.options[safeIndex],
            explanation: draft.explanation
        )
    }

    // MARK: 派生题

    /// 由知识点自身内容派生的巩固题：最多 6 道，只为把题量补到 `questionsPerPoint`。
    static func derivedDrafts(for lesson: Lesson, peers: [Lesson]) -> [PracticeDraft] {
        let capability = lesson.capabilities.first ?? .reasoning
        let plan = abilityPlan(capability)
        var drafts: [PracticeDraft] = []

        let peerSummaries = peers
            .filter { $0.id != lesson.id && $0.summary != lesson.summary }
            .map(\.summary)

        // 1. 本课的核心目标（取自本课自己的摘要）
        if let draft = draft(
            key: "\(lesson.id)-goal",
            prompt: "「\(lesson.title)」主要帮助你解决什么？",
            correct: lesson.summary,
            distractors: pick(peerSummaries, key: "\(lesson.id)-goal", count: 3),
            explanation: "「\(lesson.title)」的学习目标就是：\(lesson.summary)"
        ) { drafts.append(draft) }

        // 2. 本课归属的学习能力以及其余能力的学习方法
        let others = Capability.allCases.filter { $0 != capability }
        if let draft = draft(
            key: "\(lesson.id)-capability",
            prompt: "「\(lesson.title)」重点训练下面哪一项学习能力？",
            correct: capability.title,
            distractors: others.prefix(3).map(\.title),
            explanation: "「\(lesson.title)」在能力体系里归到「\(capability.title)」：\(capability.blurb)。"
        ) { drafts.append(draft) }

        if let draft = draft(
            key: "\(lesson.id)-strategy",
            prompt: "练习「\(lesson.title)」时，第一步应该做什么？",
            correct: plan.strategy,
            distractors: others.map { abilityPlan($0).strategy },
            explanation: "「\(capability.title)」类知识点的通用做法：\(plan.strategy)。"
        ) { drafts.append(draft) }

        if let draft = draft(
            key: "\(lesson.id)-mastery",
            prompt: "怎样才算真正掌握了「\(lesson.title)」？",
            correct: plan.mastery,
            distractors: others.map { abilityPlan($0).mastery },
            explanation: "掌握的标准是能自己用出来，而不是记住某一道题的答案。\(plan.mastery)。"
        ) { drafts.append(draft) }

        if let draft = draft(
            key: "\(lesson.id)-pitfall",
            prompt: "做「\(lesson.title)」的练习时，最容易掉进哪个坑？",
            correct: plan.pitfall,
            distractors: others.map { abilityPlan($0).pitfall },
            explanation: "需要避开的做法：\(plan.pitfall)。"
        ) { drafts.append(draft) }

        if let draft = draft(
            key: "\(lesson.id)-check",
            prompt: "做完「\(lesson.title)」的练习后，应该优先检查什么？",
            correct: plan.check,
            distractors: others.map { abilityPlan($0).check },
            explanation: "检查动作：\(plan.check)。"
        ) { drafts.append(draft) }

        return drafts
    }

    /// 每项能力对应的学习方法：策略 / 掌握标准 / 常见误区 / 检查动作。
    static func abilityPlan(_ capability: Capability) -> (strategy: String, mastery: String, pitfall: String, check: String) {
        switch capability {
        case .numberSense:
            return (
                "先观察数字特征，再决定拆分、凑整还是估算",
                "能自己想出简便算法，并说清为什么这样算",
                "没看数字就直接按竖式硬算",
                "检查数位是否对齐、估算值与精确值是否接近"
            )
        case .modeling:
            return (
                "先写清每个量表示什么，再找等量关系",
                "能把一段文字情境独立翻译成算式、方程或函数",
                "还没弄清每个量的含义就急着列式",
                "检查单位是否统一、结果回到原情境是否合理"
            )
        case .reasoning:
            return (
                "先把条件逐条列出，再判断能引用哪条性质或判定",
                "能写出完整推理，每一步都说得出依据",
                "只写结论不写依据，或把看图当成证明",
                "检查每一步的依据是否成立、结论是否由条件推出"
            )
        case .expression:
            return (
                "先想清楚要表达的结论，再按顺序组织语言",
                "能用一句话把关键的那一步讲给别人听懂",
                "心里明白，但说不清决定性的那一步",
                "检查表达里有没有说明「为什么」，而不只是「是什么」"
            )
        case .focusReflection:
            return (
                "先划定这次要完成的范围，中途不切换任务",
                "能在限定时间内完整做完审题、计算、检查三件事",
                "边做边切换任务，做完不检查就交",
                "检查有没有记下这次的卡点和下一次的具体动作"
            )
        }
    }

    // MARK: 工具

    /// 用稳定哈希（FNV-1a）决定选项顺序。
    /// Swift 的 `hashValue` 每个进程都会变，用它会让每次启动生成的题不一样。
    private static func draft(key: String, prompt: String, correct: String, distractors: [String], explanation: String) -> PracticeDraft? {
        var options: [String] = []
        for item in distractors where !options.contains(item) && item != correct {
            options.append(item)
            if options.count == 3 { break }
        }
        guard options.count == 3 else { return nil }

        let slot = Int(stableHash(key) % 4)
        options.insert(correct, at: slot)
        return PracticeDraft(prompt: prompt, options: options, answerIndex: slot, explanation: explanation)
    }

    private static func pick(_ values: [String], key: String, count: Int) -> [String] {
        var unique: [String] = []
        for value in values where !unique.contains(value) {
            unique.append(value)
        }
        return Array(unique.sorted { stableHash(key + $0) < stableHash(key + $1) }.prefix(count))
    }

    /// 稳定哈希：FNV-1a + murmur3 收尾混合。
    /// 直接用 `hashValue` 每个进程结果都不同；只做 FNV-1a 则低位分布偏斜，选项位置会失衡。
    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        hash ^= hash >> 33
        hash = hash &* 0xff51_afd7_ed55_8ccd
        hash ^= hash >> 33
        hash = hash &* 0xc4ce_b9fe_1a85_ec53
        hash ^= hash >> 33
        return hash
    }
}

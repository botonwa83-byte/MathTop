import Foundation

/// 一个学习领域下的知识点集合（能力地图、知识本、首页入口共用同一套分组）。
struct DomainGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let stage: Stage
    let lessons: [Lesson]

    var questionCount: Int { lessons.reduce(0) { $0 + $1.questions.count } }
}

/// 学习领域分组。
///
/// 分组依据是知识点自身的 `ability` 字段，顺序按课程标准里的学习顺序排定，
/// 未列入顺序表的领域按名称追加在后面，保证新增知识点不会从界面上消失。
enum DomainCatalog {
    private static let primaryOrder = [
        "数与运算", "量与计量", "代数启蒙",
        "图形几何", "统计概率", "解决问题",
        "数感雷达", "分数直觉", "找规律",
        "一年级基础", "二年级基础", "三年级基础",
        "四年级基础", "五年级基础", "六年级基础"
    ]

    private static let juniorOrder = [
        "数与式", "方程", "函数",
        "图形几何", "统计概率", "建模推理",
        "代数思维", "变化关系", "可能性",
        "七年级基础", "八年级基础", "九年级基础"
    ]

    private static func order(for stage: Stage) -> [String] {
        stage == .primary ? primaryOrder : juniorOrder
    }

    static func groups(for stage: Stage) -> [DomainGroup] {
        let lessons = MathContent.lessons(for: stage)
        let grouped = Dictionary(grouping: lessons, by: \.ability)
        let ordered = order(for: stage)
        let known = ordered.compactMap { ability -> DomainGroup? in
            guard let items = grouped[ability], !items.isEmpty else { return nil }
            return DomainGroup(id: "\(stage.rawValue)-\(ability)", title: ability, stage: stage, lessons: items)
        }
        let extra = grouped.keys
            .filter { !ordered.contains($0) }
            .sorted()
            .compactMap { ability -> DomainGroup? in
                guard let items = grouped[ability] else { return nil }
                return DomainGroup(id: "\(stage.rawValue)-\(ability)", title: ability, stage: stage, lessons: items)
            }
        return known + extra
    }

    /// 「分年级打基础」类领域（能力名以「X年级基础」结尾），首页用于区分主线与打基础。
    static func isFoundation(_ group: DomainGroup) -> Bool {
        group.title.hasSuffix("年级基础")
    }

    static func lesson(id: String) -> Lesson? {
        MathContent.lessons.first { $0.id == id }
    }
}

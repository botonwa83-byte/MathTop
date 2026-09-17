import XCTest
@testable import MathTop

/// 上线守门测试：内购划线 + 数据完整性。
/// 范式要求「内购划线靠常量 + 单测守门」，扩内容时若打乱前 N 题，这里会先失败。
@MainActor
final class MathTopTests: XCTestCase {

    // MARK: 免费档划线

    func testFreeTierPolicy() {
        let free = MathPurchaseManager.freeQuestionsPerLesson
        XCTAssertGreaterThan(free, 0)
        XCTAssertLessThanOrEqual(free, 5, "免费档不宜过大，否则失去转化钩子")

        // 每个知识点都要能提供完整免费试练，且免费之外还有付费内容
        for lesson in MathContent.lessons {
            XCTAssertGreaterThanOrEqual(
                lesson.questions.count, free,
                "知识点 \(lesson.id) 题目数不足以支撑免费试练"
            )
            XCTAssertGreaterThan(
                lesson.questions.count, free,
                "知识点 \(lesson.id) 免费档之外没有付费内容，付费墙会失去意义"
            )
        }
    }

    func testFreeSimulationBatchIsUsable() {
        let freeBatches = MathPurchaseManager.freeSimulationBatches
        XCTAssertGreaterThanOrEqual(freeBatches, 1)
        XCTAssertLessThan(freeBatches, SimulationBatch.all.count, "至少保留一批仿真题为付费内容")
        XCTAssertFalse(MathContent.simulationBatch(1).isEmpty, "第 1 批仿真题必须免费可用")
    }

    func testProductIDMatchesBundlePrefix() {
        let manager = MathPurchaseManager.shared
        XCTAssertTrue(
            manager.productID.hasPrefix("com.mathtop.app."),
            "内购产品 ID 必须与 App 的 bundle id 前缀一致，否则 ASC 无法关联"
        )
        XCTAssertEqual(manager.productID, "com.mathtop.app.full_unlock")
    }

    // MARK: 数据完整性

    func testLessonCatalogIsUniqueAndSolvable() {
        let lessons = MathContent.lessons
        XCTAssertFalse(lessons.isEmpty)
        let ids = Set(lessons.map(\.id))
        XCTAssertEqual(ids.count, lessons.count, "知识点 id 必须唯一")

        for lesson in lessons {
            let questionIDs = Set(lesson.questions.map(\.id))
            XCTAssertEqual(questionIDs.count, lesson.questions.count, "\(lesson.id) 内题目 id 重复")
            for question in lesson.questions {
                XCTAssertFalse(question.prompt.isEmpty, "\(question.id) 题干为空")
                XCTAssertFalse(question.explanation.isEmpty, "\(question.id) 缺少解析")
                XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) 选项不足")
                XCTAssertTrue(
                    question.choices.contains { $0.id == question.answer },
                    "\(question.id) 正确答案不在选项里"
                )
            }
        }
    }

    /// 第四轮补题守门：高权重知识点的题组必须真正变大（策展题 16 道，超过 10 道下限后不再被派生题截断）。
    func testWeightedKnowledgePointsGotSupplemented() {
        /// 权重依据：衔接年级基础 + 期末/中考高频 + 原有覆盖度最低
        let supplemented: Set<String> = [
            "p-unit", "p-equation", "p-fraction", "p-number-sense",
            "p-five-fraction", "p-volume1", "p-word",
            "p-six-ratio", "p-six-stat",
            "j-equation", "j-function", "j-probability",
            "j-seventh-algebra", "j-seventh-lines",
            "j-triangle", "j-data"
        ]
        let lessons = Dictionary(uniqueKeysWithValues: MathContent.lessons.map { ($0.id, $0) })
        for id in supplemented {
            let count = lessons[id]?.questions.count ?? 0
            XCTAssertGreaterThanOrEqual(count, 16, "知识点 \(id) 补题后应达到 16 道，实际 \(count)")
        }
        // 16 个知识点 × 净增 6 道 = 96 道新增练习题（超过「不少于 60 道」的要求）
        let baseline = 10
        let net = supplemented.reduce(0) { $0 + (lessons[$1]?.questions.count ?? 0) - baseline }
        XCTAssertGreaterThanOrEqual(net, 60, "本轮净增练习题应不少于 60 道，实际 \(net)")
    }

    func testSimulationBatchesAreConsistent() {
        let total = SimulationBatch.all.reduce(0) { $0 + $1.questions.count }
        XCTAssertGreaterThanOrEqual(total, 100, "三批仿真题合计应不少于 100 道")
    }
}

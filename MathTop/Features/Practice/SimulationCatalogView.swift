import SwiftUI

/// 一批固定的仿真题：100 道被拆成三批，便于集中训练和分阶段复习。
struct SimulationBatch: Identifiable {
    let number: Int
    let stage: Stage
    let title: String
    let focus: String
    let questions: [Question]

    var id: Int { number }

    var lesson: Lesson {
        Lesson(
            id: "simulation-batch-\(number)",
            title: "仿真题 · \(title)",
            ability: "综合训练",
            subject: .math,
            stage: stage,
            minutes: max(10, questions.count),
            summary: focus,
            questions: questions
        )
    }

    static let all: [SimulationBatch] = [
        SimulationBatch(
            number: 1,
            stage: .junior,
            title: "压轴精选",
            focus: "初中综合与压轴题：方程、函数、几何、统计概率逐题带解析。",
            questions: MathContent.simulationBatch(1)
        ),
        SimulationBatch(
            number: 2,
            stage: .primary,
            title: "应用与过渡",
            focus: "小学典型应用题，衔接初中收尾题与规则生成题，重点训练审题建模。",
            questions: MathContent.simulationBatch(2)
        ),
        SimulationBatch(
            number: 3,
            stage: .primary,
            title: "基础判断",
            focus: "读题、列式、检验等基础步骤判断题，适合限时快速过题。",
            questions: MathContent.simulationBatch(3)
        )
    ]
}

/// 仿真题目录：三批集中训练。
struct SimulationCatalogView: View {
    @EnvironmentObject private var store: LearningStore
    // 单例注入：付费状态是全局的，sheet / NavigationLink 都不需要再传 env
    @ObservedObject private var purchase = MathPurchaseManager.shared

    @AppStorage("simulationCompletedBatches") private var completedRaw = ""
    @State private var activeBatch: SimulationBatch?
    @State private var showPaywall = false

    private var completedNumbers: Set<Int> {
        Set(completedRaw.split(separator: ",").compactMap { Int($0) })
    }

    private var totalQuestions: Int { SimulationBatch.all.reduce(0) { $0 + $1.questions.count } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                HStack(spacing: 12) {
                    StatTile(value: "\(totalQuestions)", label: "总题量", icon: "list.number", tint: Palette.accent)
                    StatTile(value: "\(completedNumbers.count)/\(SimulationBatch.all.count)", label: "已完成批次", icon: "checkmark.seal", tint: Palette.success)
                    StatTile(
                        value: "\(totalQuestions / max(SimulationBatch.all.count, 1))",
                        label: "每批平均题量",
                        icon: "square.stack.3d.up",
                        tint: Palette.info
                    )
                }

                VStack(alignment: .leading, spacing: Metric.stack) {
                    SectionHeader(title: "选择批次", subtitle: "全部为选择题，每题都带解析")

                    VStack(spacing: 10) {
                        ForEach(SimulationBatch.all) { batch in
                            batchCard(batch)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "使用方法")
                    VStack(alignment: .leading, spacing: 8) {
                        bullet("每批约 33 道题，一次连续做完，中途可以退出，已经做过的题都会记入练习统计。")
                        bullet("做完一批会留下完成标记，三批可以按周推进，也可以考前集中过。")
                        bullet("仿真题不写入知识点掌握率，只作为综合练手，不会影响能力地图的进度。")
                    }
                    .surfaceCard()
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .mathReadableWidth()
        }
        .screenBackground()
        .navigationTitle("仿真题训练")
        .sheet(item: $activeBatch) { batch in
            PracticeView(lesson: batch.lesson, chunkSize: nil) {
                markCompleted(batch.number)
            }
            .environmentObject(store)
            .environmentObject(purchase)
        }
        .sheet(isPresented: $showPaywall) { MathPaywallView() }
    }

    private func batchCard(_ batch: SimulationBatch) -> some View {
        let done = completedNumbers.contains(batch.number)
        let locked = purchase.isSimulationBatchLocked(batch.number)
        return Button {
            if locked { showPaywall = true } else { activeBatch = batch }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(done ? Palette.success : batch.stage.tint.opacity(0.14))
                        Text("\(batch.number)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(done ? .white : batch.stage.tint)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("第 \(batch.number) 批 · \(batch.title)")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Palette.textPrimary)
                        HStack(spacing: 6) {
                            TagBadge(text: "\(batch.questions.count) 题", tint: Palette.textSecondary)
                            TagBadge(text: batch.stage.rawValue, tint: batch.stage.tint)
                            if done { TagBadge(text: "已完成", tint: Palette.success, icon: "checkmark") }
                            if locked { TagBadge(text: "完整版", tint: Palette.warning, icon: "lock.fill") }
                        }
                    }
                    Spacer(minLength: 4)
                    Image(systemName: locked ? "lock.fill" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
                Text(batch.focus)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Palette.accent).frame(width: 5, height: 5).padding(.top, 7)
            Text(text)
                .font(AppFont.caption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func markCompleted(_ number: Int) {
        var numbers = completedNumbers
        numbers.insert(number)
        completedRaw = numbers.sorted().map(String.init).joined(separator: ",")
    }
}

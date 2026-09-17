import SwiftUI

/// 完整版解锁付费墙：免费试练 3 题 → 完整题组 + 进阶模块 + 仿真全三批。
struct MathPaywallView: View {
    @ObservedObject private var purchase = MathPurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    /// 价格以 ASC 为准；拉取失败时显示占位，避免长期展示与后台不一致的兜底价。
    private var priceLabel: String { purchase.product?.displayPrice ?? "—" }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Metric.sectionGap) {
                    hero
                    benefits
                    freeTierNote
                    purchaseArea
                }
                .padding(.horizontal, Metric.gutter)
                .padding(.top, Metric.chipGap)
                .padding(.bottom, Metric.pageBottom)
                .mathReadableWidth()
            }
            .screenBackground()
            .navigationTitle("解锁完整版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .font(AppFont.body)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .onChange(of: purchase.isUnlocked) { unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "function")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
            Text("解锁数学登顶完整版")
                .font(AppFont.screenTitle)
                .foregroundStyle(Palette.textPrimary)
            Text("\(MathContent.lessons.count) 个知识点的完整题组、五个进阶方向、仿真题全三批，一次买断永久使用。")
                .font(AppFont.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .surfaceCard()
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "解锁后你能得到")
            VStack(spacing: 10) {
                benefitRow("每个知识点的完整题组", subtitle: "每个知识点不少于 \(LessonPracticeFactory.questionsPerPoint) 道，含解析与错因定位", tint: Palette.accent, icon: "pencil.and.outline")
                benefitRow("仿真题集中训练全三批", subtitle: "100 道限时集中过题，适合考前冲刺", tint: Palette.info, icon: "list.number")
                benefitRow("进阶模块五个方向", subtitle: "竞赛压轴、几何实验室、应用题冲刺、复盘与阶段测评", tint: Palette.success, icon: "sparkles")
                benefitRow("一次买断，永久使用", subtitle: "无订阅、无续费，支持换机恢复购买", tint: Palette.warning, icon: "infinity")
            }
        }
    }

    private var freeTierNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("永久免费的部分")
                .font(AppFont.cardTitle)
                .foregroundStyle(Palette.textPrimary)
            Text("每个知识点前 \(MathPurchaseManager.freeQuestionsPerLesson) 题试练、仿真第 1 批（34 题）、错题变身器、成长摘要、收藏与能力地图浏览——不花钱也能长期用。")
                .font(AppFont.caption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .surfaceCard()
    }

    private var purchaseArea: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: purchase.isPurchasing ? "处理中…" : "立即解锁  \(priceLabel)",
                icon: "lock.open.fill",
                tint: Palette.accent,
                enabled: !purchase.isPurchasing
            ) {
                Task { await purchase.purchase() }
            }
            Button {
                Task { await purchase.restore() }
            } label: {
                Text("恢复购买")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .underline()
            }
            .disabled(purchase.isPurchasing)

            if let error = purchase.errorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if purchase.productLoadFailed {
                HStack(spacing: 8) {
                    Text("价格暂时无法加载，请检查网络")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.warning)
                    Button("重试") { Task { await purchase.retryLoadProduct() } }
                        .font(AppFont.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("购买即视为同意《用户协议》与《隐私政策》。付款通过 Apple 账户完成，换机后可用「恢复购买」找回。")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                MathLegalLinksView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func benefitRow(_ title: String, subtitle: String, tint: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(AppFont.subhead)
                .foregroundStyle(tint)
                .frame(width: Metric.iconBox, height: Metric.iconBox)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

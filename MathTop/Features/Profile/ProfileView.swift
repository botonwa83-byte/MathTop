import SwiftUI

/// 我的：学习档案、工具入口与成长摘要。
struct ProfileView: View {
    @EnvironmentObject private var store: LearningStore

    private var summary: GrowthSummary { GrowthSummaryService.make(store: store) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Metric.sectionGap) {
                    profileCard
                    overviewGrid
                    toolsSection
                    aboutSection
                }
                .padding(.horizontal, Metric.gutter)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .screenBackground()
            .navigationTitle("我的")
        }
    }

    private var profileCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Palette.accent.opacity(0.9), Color(hex: 0x8A6BE2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "figure.walk.motion").font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text("数学登顶学员").font(AppFont.sectionTitle).foregroundStyle(Palette.textPrimary)
                Text("小学数学 · 初中数学 · 五维能力训练")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                HStack(spacing: 6) {
                    TagBadge(text: "连续 \(summary.streak) 天", tint: Palette.streak, icon: "flame.fill")
                    TagBadge(text: "任务包 \(summary.sessions)", tint: Palette.success, icon: "checkmark.seal")
                }
            }
            Spacer(minLength: 4)
            ProgressRing(value: summary.mastery, size: 60, lineWidth: 7, tint: Palette.accent, caption: "掌握")
        }
        .surfaceCard()
    }

    private var overviewGrid: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "学习档案", subtitle: "全部学段合计")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                StatTile(value: "\(summary.completed)/\(summary.total)", label: "已解锁知识点", icon: "checkmark.seal.fill", tint: Palette.success)
                StatTile(value: "\(summary.attempts)", label: "累计练习题", icon: "pencil.and.outline", tint: Palette.accent)
                StatTile(value: "\(summary.incorrect)", label: "待复习错题", icon: "arrow.uturn.backward", tint: Palette.warning)
                StatTile(value: "\(summary.reflections)", label: "复盘记录", icon: "text.bubble", tint: Palette.info)
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "学习工具")
            VStack(spacing: 10) {
                NavigationLink { GrowthSummaryView() } label: {
                    ActionRow(
                        icon: "chart.bar.xaxis",
                        title: "成长摘要",
                        subtitle: "五维能力明细、7 天趋势与下一步建议",
                        tint: Palette.accent
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { SimulationCatalogView() } label: {
                    ActionRow(
                        icon: "list.number",
                        title: "仿真题集中训练",
                        subtitle: "100 道题分三批，适合限时集中过题",
                        tint: Palette.info,
                        trailingText: "100 题"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { ErrorBookView() } label: {
                    ActionRow(
                        icon: "arrow.uturn.backward.circle",
                        title: "错题变身器",
                        subtitle: "按 1 天 / 7 天间隔复习",
                        tint: Palette.warning,
                        trailingText: "\(summary.incorrect)"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { FavoriteListView() } label: {
                    ActionRow(
                        icon: "bookmark",
                        title: "我的收藏",
                        subtitle: "常错或常看的知识点收在这里",
                        tint: Palette.accent
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { MathPremiumCatalogView() } label: {
                    ActionRow(
                        icon: "sparkles",
                        title: "进阶模块",
                        subtitle: "竞赛压轴、几何实验室、应用题冲刺、阶段测评",
                        tint: Color(hex: 0x8A6BE2),
                        trailingText: "\(MathPremiumModule.all.count) 个"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "关于")
            VStack(alignment: .leading, spacing: 10) {
                aboutRow("知识点总数", "\(MathContent.lessons.count) 个")
                aboutRow("配套练习总数", "\(MathContent.lessons.reduce(0) { $0 + $1.questions.count }) 道")
                aboutRow("每个知识点配套题量", "不少于 \(LessonPracticeFactory.questionsPerPoint) 道")
                aboutRow("学习活动库", "\(MathContent.learningActivities.count) 个情境任务")
                Divider().overlay(Palette.line)
                Text("MathTop · 数学登顶  v1.0.0\n© 2026 Top King. All rights reserved.")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .surfaceCard()
        }
    }

    private func aboutRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(AppFont.body).foregroundStyle(Palette.textSecondary)
            Spacer()
            Text(value).font(AppFont.body.bold()).foregroundStyle(Palette.textPrimary)
        }
    }
}

/// 成长摘要：把五维能力、趋势与建议集中展示。
struct GrowthSummaryView: View {
    @EnvironmentObject private var store: LearningStore

    private var summary: GrowthSummary { GrowthSummaryService.make(store: store) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                HStack(spacing: 16) {
                    ProgressRing(value: summary.mastery, size: 84, lineWidth: 9, tint: Palette.accent, caption: "掌握率")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("已解锁 \(summary.completed) / \(summary.total) 个知识点")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Palette.textPrimary)
                        Text("累计练习 \(summary.attempts) 题，其中错题 \(summary.incorrect) 道待复习。")
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            TagBadge(text: "连续 \(summary.streak) 天", tint: Palette.streak, icon: "flame.fill")
                            TagBadge(text: "任务包 \(summary.sessions)", tint: Palette.success)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .surfaceCard()

                VStack(alignment: .leading, spacing: Metric.stack) {
                    SectionHeader(title: "五维能力明细", subtitle: "近 30 天加权计算")
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(summary.capabilitySnapshots) { snapshot in
                            CapabilityBar(
                                capability: snapshot.capability,
                                mastery: snapshot.mastery,
                                trend: snapshot.trend,
                                practiceCount: snapshot.practiceCount,
                                showsBlurb: snapshot.practiceCount == 0
                            )
                        }
                    }
                    .surfaceCard()
                }

                if let top = summary.topCapability, let weak = summary.weakCapability {
                    VStack(alignment: .leading, spacing: Metric.stack) {
                        SectionHeader(title: "优势与待加强")
                        VStack(spacing: 10) {
                            highlightRow(
                                icon: "arrow.up.right",
                                title: "当前优势：\(top.capability.title)",
                                message: top.recommendation,
                                tint: Palette.success
                            )
                            highlightRow(
                                icon: "exclamationmark",
                                title: "优先加强：\(weak.capability.title)",
                                message: weak.recommendation,
                                tint: Palette.warning
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Metric.stack) {
                    SectionHeader(title: "近 7 天活动", subtitle: "理解、练习、迁移、复盘都计入")
                    VStack(alignment: .leading, spacing: 12) {
                        MiniBarChart(values: summary.sevenDayActivityCounts, tint: Palette.accent)
                        Text("下一步建议：\(summary.nextStep)")
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .surfaceCard()
                }
            }
            .padding(Metric.gutter)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationTitle("成长摘要")
    }

    private func highlightRow(icon: String, title: String, message: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

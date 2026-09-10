import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var stage: Stage = .primary
    @State private var showPractice = false
    @State private var runningActivity: LearningActivity?
    @State private var scrollTarget: String? = LaunchOptions.scrollTarget

    private var dailyPlan: DailyPlan { DailyPlanService.makePlan(stage: stage, store: store) }
    private var summary: GrowthSummary { GrowthSummaryService.make(store: store) }
    private var domains: [DomainGroup] { DomainCatalog.groups(for: stage) }

    private var stageLessons: [Lesson] { MathContent.lessons(for: stage) }
    private var completedInStage: Int { stageLessons.filter { store.completedLessonIDs.contains($0.id) }.count }
    private var stageMastery: Double {
        stageLessons.isEmpty ? 0 : Double(completedInStage) / Double(stageLessons.count)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        greeting.id("greeting")
                        StageSegmentedControl(stage: $stage)
                        todayTaskSection
                        overviewSection.id("overview")
                        capabilitySection.id("capability")
                        if dailyPlan.dueReviewCount > 0 { dueReviewBanner }
                        domainSection.id("domains")
                        continueSection.id("continue")
                        trainingSection.id("training")
                        weeklySection.id("weekly")
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .onAppear {
                    guard let target = scrollTarget else { return }
                    scrollTarget = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(target, anchor: .top) }
                    }
                }
            }
            .screenBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $showPractice) {
                if let activity = dailyPlan.session.activities.first(where: { $0.mode == .practice }) {
                    PracticeView(lesson: dailyPlan.primary, session: dailyPlan.session, activity: activity) {}
                        .environmentObject(store)
                }
            }
            .sheet(item: $runningActivity) { activity in
                ActivitySheet(activity: activity) {
                    store.completeActivity(activity, in: dailyPlan.session)
                    runningActivity = nil
                }
                .environmentObject(store)
            }
        }
    }

    // MARK: 问候

    private var greeting: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MATHTOP · \(stage.rawValue)数学")
                    .font(AppFont.label)
                    .tracking(1.4)
                    .foregroundStyle(Palette.accent)
                Text(greetingText)
                    .font(AppFont.screenTitle)
                    .foregroundStyle(Palette.textPrimary)
                Text("把文字情境变成数量关系，把陌生题拆成能执行的步骤。")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            VStack(spacing: 6) {
                ProgressRing(value: stageMastery, size: 62, lineWidth: 7, tint: stage.tint, caption: stage.rawValue)
                if store.streak > 0 {
                    TagBadge(text: "连续 \(store.streak) 天", tint: Palette.streak, icon: "flame.fill")
                }
            }
        }
    }

    private var greetingText: String {
        if store.attempts.isEmpty { return "今天开始第一次训练" }
        if dailyPlan.session.isCompleted { return "今日任务已完成" }
        return "再来 10 分钟，解锁新能力"
    }

    // MARK: 今日任务

    private var todayTaskSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(
                title: "今日任务包",
                subtitle: dailyPlan.primary.title,
                trailing: "约 \(max(dailyPlan.estimatedMinutes, 5)) 分钟"
            )

            let session = dailyPlan.session
            let done = session.completedActivityIDs.count

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.isCompleted ? "今天的能力已经解锁" : "四步能力闭环")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Palette.textPrimary)
                        Text(session.isCompleted ? "明天继续点亮新的知识点。" : "理解 → 练习 → 迁移 → 复盘，一次走完。")
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            TagBadge(text: dailyPlan.primary.ability, tint: dailyPlan.primary.stage.tint)
                            TagBadge(text: "\(dailyPlan.primary.questions.count) 题", tint: Palette.textSecondary)
                            if let weak = dailyPlan.weakCapability {
                                TagBadge(text: "补 \(weak.title)", tint: weak.tint, icon: weak.systemImage)
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    ProgressRing(
                        value: Double(done) / Double(max(session.activities.count, 1)),
                        size: 58,
                        lineWidth: 6,
                        tint: Palette.accent,
                        caption: "\(done)/\(session.activities.count)"
                    )
                }

                Divider().overlay(Palette.line)

                VStack(spacing: 12) {
                    ForEach(session.activities) { activity in
                        Button {
                            open(activity)
                        } label: {
                            ChecklistRow(
                                mode: activity.mode,
                                title: activity.title,
                                minutes: activity.minutes,
                                completed: session.completedActivityIDs.contains(activity.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                PrimaryButton(
                    title: session.isCompleted ? "再练一次" : (done == 0 ? "开始今日训练" : "继续今日训练"),
                    icon: "arrow.right",
                    tint: Palette.action
                ) {
                    open(nextActivity(in: session))
                }
            }
            .surfaceCard()
        }
    }

    private func nextActivity(in session: StudySession) -> LearningActivity {
        session.activities.first { !session.completedActivityIDs.contains($0.id) } ?? session.activities[0]
    }

    private func open(_ activity: LearningActivity) {
        if activity.mode == .practice {
            showPractice = true
        } else {
            runningActivity = activity
        }
    }

    // MARK: 学习总览

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "学习总览", subtitle: "\(stage.rawValue) · 共 \(stageLessons.count) 个知识点")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                StatTile(value: "\(completedInStage)", label: "已掌握知识点", icon: "checkmark.seal.fill", tint: Palette.success)
                StatTile(value: "\(store.attempts.count)", label: "累计练习题", icon: "pencil.and.outline", tint: Palette.accent)
                StatTile(value: "\(store.streak)", label: "连续学习天数", icon: "flame.fill", tint: Palette.streak)
                StatTile(value: "\(store.incorrectAttempts.count)", label: "待复习错题", icon: "arrow.uturn.backward", tint: Palette.warning)
            }
        }
    }

    // MARK: 五维能力

    private var capabilitySection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "能力成长", subtitle: "近 30 天 · 理解与练习都在累积", trailing: "共 \(summary.attempts) 题")
            VStack(alignment: .leading, spacing: 16) {
                ForEach(summary.capabilitySnapshots) { snapshot in
                    CapabilityBar(
                        capability: snapshot.capability,
                        mastery: snapshot.mastery,
                        trend: snapshot.trend,
                        practiceCount: snapshot.practiceCount
                    )
                }
                Divider().overlay(Palette.line)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.accent)
                    Text(summary.nextStep)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                NavigationLink { GrowthSummaryView() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis").font(.system(size: 13, weight: .semibold))
                        Text("查看成长摘要").font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Metric.tapTarget)
                    .foregroundStyle(Palette.textPrimary)
                    .background(Palette.paper)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .surfaceCard()
        }
    }

    private var dueReviewBanner: some View {
        NavigationLink { ErrorBookView() } label: {
            NoticeBanner(
                icon: "clock.badge.exclamationmark",
                title: "有 \(dailyPlan.dueReviewCount) 道错题该复习了",
                message: "按 1 天 / 7 天的间隔复习，趁热把错题变成得分点。",
                tint: Palette.warning
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: 按领域浏览

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "按领域浏览", subtitle: "点一个领域，直接看它下面的知识点")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(domains) { group in
                        NavigationLink { DomainLessonListView(group: group) } label: {
                            domainChip(group)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
            .padding(.trailing, -Metric.gutter)
        }
    }

    private func domainChip(_ group: DomainGroup) -> some View {
        let done = group.lessons.filter { store.completedLessonIDs.contains($0.id) }.count
        let ratio = group.lessons.isEmpty ? 0 : Double(done) / Double(group.lessons.count)
        return VStack(alignment: .leading, spacing: 8) {
            Text(group.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
            Text("\(group.lessons.count) 个知识点 · \(group.questionCount) 题")
                .font(AppFont.caption)
                .foregroundStyle(Palette.textSecondary)
            ProgressView(value: max(ratio, 0.001)).tint(DomainCatalog.isFoundation(group) ? Palette.info : stage.tint)
            Text("已掌握 \(done)/\(group.lessons.count)")
                .font(AppFont.label)
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(14)
        .frame(width: 176, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    // MARK: 继续学习

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "继续学习", subtitle: "接着上一个知识点往下走")
            if let lesson = dailyPlan.next ?? stageLessons.first(where: { !store.completedLessonIDs.contains($0.id) }) {
                NavigationLink { SkillDetailView(lesson: lesson) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: lesson.capabilities.first?.systemImage ?? "function")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(lesson.stage.tint)
                            .frame(width: Metric.iconBox, height: Metric.iconBox)
                            .background(lesson.stage.tint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                            Text(lesson.summary)
                                .font(AppFont.caption)
                                .foregroundStyle(Palette.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 6) {
                                TagBadge(text: lesson.ability, tint: lesson.stage.tint)
                                TagBadge(text: "\(lesson.questions.count) 道配套练习", tint: Palette.success)
                            }
                        }
                        Spacer(minLength: 6)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Text("这个学段的知识点都练过了，去能力地图换一个学段吧。")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: 专项训练

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "专项训练", subtitle: "集中突破与查漏补缺")
            VStack(spacing: 10) {
                NavigationLink { SimulationCatalogView() } label: {
                    ActionRow(
                        icon: "list.number",
                        title: "仿真题集中训练",
                        subtitle: "100 道小学 / 初中仿真题，分三批推进",
                        tint: Palette.accent,
                        trailingText: "\(SimulationBatch.all.reduce(0) { $0 + $1.questions.count }) 题"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { ErrorBookView() } label: {
                    ActionRow(
                        icon: "arrow.uturn.backward.circle",
                        title: "错题变身器",
                        subtitle: "把答错的题按间隔复习重新做一遍",
                        tint: Palette.warning,
                        trailingText: "\(store.incorrectAttempts.count)"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { DomainListView(stage: stage) } label: {
                    ActionRow(
                        icon: "list.bullet.rectangle",
                        title: "知识清单",
                        subtitle: "\(stage.rawValue)全部 \(stageLessons.count) 个知识点与配套题量",
                        tint: Palette.info,
                        trailingText: "\(stageLessons.reduce(0) { $0 + $1.questions.count }) 题"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink { MathPremiumCatalogView() } label: {
                    ActionRow(
                        icon: "sparkles",
                        title: "进阶模块",
                        subtitle: "竞赛压轴、几何实验室、应用题冲刺与阶段测评",
                        tint: Color(hex: 0x8A6BE2),
                        trailingText: "\(MathPremiumModule.all.count) 个"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: 近 7 天

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(title: "近 7 天学习", subtitle: "每天完成的活动次数")
            VStack(alignment: .leading, spacing: 12) {
                MiniBarChart(values: summary.sevenDayActivityCounts, tint: Palette.accent)
                HStack {
                    Text("近 7 天共完成 \(summary.sevenDayActivityCounts.reduce(0, +)) 个学习活动")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                    Spacer()
                    Text("复盘 \(summary.reflections) 次")
                        .font(AppFont.caption.bold())
                        .foregroundStyle(Palette.success)
                }
            }
            .surfaceCard()
        }
    }
}

// MARK: - 非做题类学习活动

/// 理解 / 迁移 / 复盘类活动：展示情境、成功标准与反馈，确认后记入能力成长。
struct ActivitySheet: View {
    let activity: LearningActivity
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedChoice: String?

    private var requiresChoice: Bool { !activity.choices.isEmpty }
    private var canFinish: Bool { !requiresChoice || selectedChoice != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 8) {
                        TagBadge(text: activity.mode.title, tint: activity.mode.tint, icon: activity.mode.systemImage)
                        TagBadge(text: "\(activity.minutes) 分钟", tint: Palette.textSecondary)
                        ForEach(activity.capabilities) { capability in
                            TagBadge(text: capability.shortTitle, tint: capability.tint)
                        }
                    }

                    Text(activity.title)
                        .font(AppFont.screenTitle)
                        .foregroundStyle(Palette.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("情境").font(AppFont.label).tracking(1.2).foregroundStyle(Palette.textTertiary)
                        Text(activity.prompt)
                            .font(AppFont.body)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .surfaceCard()

                    if requiresChoice {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("选一个最贴近你的情况").font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                            ForEach(activity.choices, id: \.self) { choice in
                                Button { selectedChoice = choice } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: selectedChoice == choice ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(selectedChoice == choice ? Palette.accent : Palette.textTertiary)
                                        Text(choice).font(AppFont.body).foregroundStyle(Palette.textPrimary)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(13)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selectedChoice == choice ? Palette.accent.opacity(0.08) : Palette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous)
                                            .stroke(selectedChoice == choice ? Palette.accent : Palette.line, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal").foregroundStyle(Palette.success)
                            Text("完成标准").font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                        }
                        Text(activity.successCriteria)
                            .font(AppFont.body)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider().overlay(Palette.line)
                        Text(activity.feedback)
                            .font(AppFont.caption)
                            .foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .surfaceCard()

                    PrimaryButton(title: "完成这一步", icon: "checkmark", enabled: canFinish) {
                        onDone()
                        dismiss()
                    }
                }
                .padding(Metric.gutter)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }.foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }
}

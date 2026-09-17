import SwiftUI

/// 能力地图：先看五维能力的成长位置，再按学习领域逐个知识点往下走。
struct PathView: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var stage: Stage = .primary

    private var summary: GrowthSummary { store.growthSummary }
    private var domains: [DomainGroup] { DomainCatalog.groups(for: stage) }

    var body: some View {
        PerfProbe.tick("PathView")
        return NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Metric.sectionGap) {
                    StageSegmentedControl(stage: $stage)
                    capabilityOverview
                    domainSections
                }
                .padding(.horizontal, Metric.gutter)
                .padding(.top, Metric.tight)
                .padding(.bottom, Metric.pageBottom)
                .mathReadableWidth()
            }
            .screenBackground()
            .navigationTitle("能力地图")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: 五维能力

    private var capabilityOverview: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            SectionHeader(
                title: "五维能力位置",
                subtitle: "用理解、练习、迁移、复盘四类活动累积",
                trailing: "近 30 天"
            )
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
                Divider().overlay(Palette.line)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(AppFont.footnote)
                        .foregroundStyle(Palette.accent)
                    Text(summary.nextStep)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            .surfaceCard()
        }
    }

    // MARK: 领域分组

    private var domainSections: some View {
        ForEach(domains) { group in
            VStack(alignment: .leading, spacing: Metric.stack) {
                let done = group.lessons.filter { store.completedLessonIDs.contains($0.id) }.count
                SectionHeader(
                    title: group.title,
                    subtitle: DomainCatalog.isFoundation(group) ? "分年级打基础" : "\(group.questionCount) 道配套练习",
                    trailing: "\(done)/\(group.lessons.count)"
                )
                VStack(spacing: 10) {
                    ForEach(group.lessons) { lesson in
                        NavigationLink { SkillDetailView(lesson: lesson) } label: {
                            LessonRow(lesson: lesson, completed: store.completedLessonIDs.contains(lesson.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// 知识点行：能力标签 + 标题 + 配套题量 + 掌握状态。
struct LessonRow: View {
    let lesson: Lesson
    var completed: Bool
    var showsSummary = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: completed ? "checkmark" : (lesson.capabilities.first?.systemImage ?? "circle.dashed"))
                .font(AppFont.subhead)
                .foregroundStyle(completed ? .white : lesson.stage.tint)
                .frame(width: Metric.iconBox, height: Metric.iconBox)
                .background(completed ? Palette.success : lesson.stage.tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                if showsSummary {
                    Text(lesson.summary)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 6) {
                    TagBadge(text: "\(lesson.questions.count) 道练习", tint: Palette.success)
                    TagBadge(text: "\(lesson.minutes) 分钟", tint: Palette.textSecondary)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(AppFont.captionStrong).foregroundStyle(Palette.textTertiary)
        }
        .padding(Metric.fieldPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

/// 知识点详情：学习目标、能力标签、题组结构和练习入口。
struct SkillDetailView: View {
    let lesson: Lesson

    @EnvironmentObject private var store: LearningStore
    @AppStorage("favoriteLessonIDs") private var favoritesRaw = ""
    @State private var showPractice = false

    private var isFavorite: Bool { favoriteIDs.contains(lesson.id) }
    private var favoriteIDs: Set<String> { Set(favoritesRaw.split(separator: ",").map(String.init)) }
    private var batches: Int { LessonPracticeFactory.batchCount(for: lesson.questions) }
    private var completed: Bool { store.completedLessonIDs.contains(lesson.id) }
    private var lessonAttempts: [Attempt] { store.attempts.filter { $0.lessonID == lesson.id } }
    private var accuracy: Double {
        lessonAttempts.isEmpty ? 0 : Double(lessonAttempts.filter(\.correct).count) / Double(lessonAttempts.count)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        TagBadge(text: lesson.ability, tint: lesson.stage.tint)
                        TagBadge(text: lesson.stage.rawValue, tint: lesson.stage.tint, icon: lesson.stage.systemImage)
                        if completed { TagBadge(text: "已掌握", tint: Palette.success, icon: "checkmark") }
                    }
                    Text(lesson.title).font(AppFont.screenTitle).foregroundStyle(Palette.textPrimary)
                    Text(lesson.summary)
                        .font(AppFont.body)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(lesson.questions.count)", label: "配套练习", icon: "list.number", tint: Palette.accent)
                    StatTile(value: "\(batches)", label: "练习批次", icon: "square.stack.3d.up", tint: Palette.info)
                    StatTile(
                        value: lessonAttempts.isEmpty ? "—" : "\(Int(accuracy * 100))%",
                        label: "本课正确率",
                        icon: "target",
                        tint: Palette.success
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("这项知识点在练什么").font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                    ForEach(lesson.capabilities) { capability in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: capability.systemImage)
                                .font(AppFont.captionStrong)
                                .foregroundStyle(capability.tint)
                                .frame(width: 24, height: 24)
                                .background(capability.tint.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: Metric.radiusDot, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(capability.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                                Text(capability.blurb).font(AppFont.caption).foregroundStyle(Palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .surfaceCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("练习安排").font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                    Text("共 \(lesson.questions.count) 道题，每批 \(LessonPracticeFactory.batchSize) 道，分 \(batches) 批完成。每道题都有解析，答错会自动进入错题本。")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(0..<batches, id: \.self) { index in
                        let items = LessonPracticeFactory.batch(lesson.questions, index: index)
                        HStack(spacing: 8) {
                            TagBadge(text: "第 \(index + 1) 批", tint: Palette.info)
                            Text("\(items.count) 道题")
                                .font(AppFont.caption)
                                .foregroundStyle(Palette.textSecondary)
                            Spacer(minLength: 0)
                            Text(items.first?.prompt ?? "")
                                .font(AppFont.caption)
                                .foregroundStyle(Palette.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                .surfaceCard()

                PrimaryButton(title: completed ? "再练一遍" : "开始练习", icon: "play.fill") {
                    showPractice = true
                }
            }
            .padding(Metric.gutter)
            .padding(.bottom, Metric.blockGap)
        }
        .screenBackground()
        .navigationTitle("知识点详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isFavorite ? Palette.accent : Palette.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showPractice) {
            PracticeView(lesson: lesson) {
                store.markLessonCompleted(lesson)
            }
            .environmentObject(store)
        }
    }

    private func toggleFavorite() {
        var ids = favoriteIDs
        if ids.contains(lesson.id) { ids.remove(lesson.id) } else { ids.insert(lesson.id) }
        favoritesRaw = ids.sorted().joined(separator: ",")
    }
}

/// 单个领域下的知识点清单。
struct DomainLessonListView: View {
    let group: DomainGroup

    @EnvironmentObject private var store: LearningStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.stack) {
                HStack(spacing: 12) {
                    StatTile(value: "\(group.lessons.count)", label: "知识点", icon: "book.closed", tint: Palette.info)
                    StatTile(value: "\(group.questionCount)", label: "配套练习", icon: "list.number", tint: Palette.accent)
                    StatTile(
                        value: "\(group.lessons.filter { store.completedLessonIDs.contains($0.id) }.count)",
                        label: "已掌握",
                        icon: "checkmark.seal",
                        tint: Palette.success
                    )
                }
                VStack(spacing: 10) {
                    ForEach(group.lessons) { lesson in
                        NavigationLink { SkillDetailView(lesson: lesson) } label: {
                            LessonRow(lesson: lesson, completed: store.completedLessonIDs.contains(lesson.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Metric.gutter)
            .padding(.bottom, Metric.blockGap)
        }
        .screenBackground()
        .navigationTitle(group.title)
    }
}

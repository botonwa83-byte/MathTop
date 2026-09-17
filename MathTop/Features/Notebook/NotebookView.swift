import SwiftUI

/// 知识本：收藏、分学段清单与错题本。
struct NotebookView: View {
    @EnvironmentObject private var store: LearningStore

    @AppStorage("favoriteLessonIDs") private var favoritesRaw = ""

    private var favoriteIDs: Set<String> { Set(favoritesRaw.split(separator: ",").map(String.init)) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Metric.sectionGap) {
                    HStack(spacing: 12) {
                        StatTile(value: "\(MathContent.lessons.count)", label: "全部知识点", icon: "book.closed", tint: Palette.info)
                        StatTile(
                            value: "\(MathContent.lessons.reduce(0) { $0 + $1.questions.count })",
                            label: "配套练习总量",
                            icon: "list.number",
                            tint: Palette.accent
                        )
                        StatTile(value: "\(store.incorrectAttempts.count)", label: "待复习错题", icon: "arrow.uturn.backward", tint: Palette.warning)
                    }

                    VStack(alignment: .leading, spacing: Metric.stack) {
                        SectionHeader(title: "学习清单", subtitle: "按学段与领域查看知识点")
                        VStack(spacing: 10) {
                            ForEach(Stage.allCases, id: \.self) { stage in
                                NavigationLink { DomainListView(stage: stage) } label: {
                                    ActionRow(
                                        icon: stage.systemImage,
                                        title: "\(stage.rawValue)数学知识点",
                                        subtitle: stage.subtitle,
                                        tint: stage.tint,
                                        trailingText: "\(MathContent.lessons(for: stage).count) 个"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            NavigationLink { ErrorBookView() } label: {
                                ActionRow(
                                    icon: "arrow.uturn.backward.circle",
                                    title: "错题变身器",
                                    subtitle: "按间隔复习安排，把错题重做一遍",
                                    tint: Palette.warning,
                                    trailingText: "\(store.incorrectAttempts.count)"
                                )
                            }
                            .buttonStyle(.plain)
                            NavigationLink { FavoriteListView() } label: {
                                ActionRow(
                                    icon: "bookmark",
                                    title: "我的收藏",
                                    subtitle: "在知识点详情页点书签即可收藏",
                                    tint: Palette.accent,
                                    trailingText: "\(favoriteIDs.count)"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: Metric.stack) {
                        SectionHeader(title: "学过什么", subtitle: "最近练习过的知识点")
                        if store.completedLessonIDs.isEmpty {
                            EmptyStateView(
                                icon: "book.closed",
                                title: "还没有学习记录",
                                message: "完成任意一个知识点的练习，这里就会留下痕迹。",
                                tint: Palette.info
                            )
                            .surfaceCard()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(recentLessons) { lesson in
                                    NavigationLink { SkillDetailView(lesson: lesson) } label: {
                                        LessonRow(lesson: lesson, completed: true, showsSummary: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Metric.gutter)
                .padding(.top, Metric.tight)
                .padding(.bottom, Metric.pageBottom)
                .mathReadableWidth()
            }
            .screenBackground()
            .navigationTitle("知识本")
        }
    }

    private var recentLessons: [Lesson] {
        MathContent.lessons.filter { store.completedLessonIDs.contains($0.id) }.prefix(8).map { $0 }
    }
}

/// 按领域展开的学段知识清单。
struct DomainListView: View {
    let stage: Stage

    @EnvironmentObject private var store: LearningStore

    private var domains: [DomainGroup] { DomainCatalog.groups(for: stage) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                HStack(spacing: 12) {
                    StatTile(
                        value: "\(MathContent.lessons(for: stage).count)",
                        label: "知识点",
                        icon: stage.systemImage,
                        tint: stage.tint
                    )
                    StatTile(
                        value: "\(MathContent.lessons(for: stage).reduce(0) { $0 + $1.questions.count })",
                        label: "配套练习",
                        icon: "list.number",
                        tint: Palette.accent
                    )
                    StatTile(value: "\(domains.count)", label: "学习领域", icon: "square.grid.2x2", tint: Palette.info)
                }

                ForEach(domains) { group in
                    VStack(alignment: .leading, spacing: Metric.stack) {
                        let done = group.lessons.filter { store.completedLessonIDs.contains($0.id) }.count
                        SectionHeader(
                            title: group.title,
                            subtitle: "\(group.lessons.count) 个知识点 · \(group.questionCount) 题",
                            trailing: "\(done)/\(group.lessons.count)"
                        )
                        VStack(spacing: 10) {
                            ForEach(group.lessons) { lesson in
                                NavigationLink { SkillDetailView(lesson: lesson) } label: {
                                    LessonRow(lesson: lesson, completed: store.completedLessonIDs.contains(lesson.id), showsSummary: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.top, Metric.tight)
            .padding(.bottom, Metric.pageBottom)
        }
        .screenBackground()
        .navigationTitle("\(stage.rawValue)数学")
    }
}

/// 收藏的知识点。
struct FavoriteListView: View {
    @EnvironmentObject private var store: LearningStore

    @AppStorage("favoriteLessonIDs") private var favoritesRaw = ""

    private var lessons: [Lesson] {
        let ids = Set(favoritesRaw.split(separator: ",").map(String.init))
        return MathContent.lessons.filter { ids.contains($0.id) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                if lessons.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "还没有收藏",
                        message: "在任意知识点详情页右上角点一下书签，就会出现在这里。",
                        tint: Palette.accent
                    )
                    .surfaceCard()
                } else {
                    ForEach(lessons) { lesson in
                        NavigationLink { SkillDetailView(lesson: lesson) } label: {
                            LessonRow(lesson: lesson, completed: store.completedLessonIDs.contains(lesson.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.top, Metric.tight)
            .padding(.bottom, Metric.pageBottom)
        }
        .screenBackground()
        .navigationTitle("我的收藏")
    }
}

/// 错题本：按知识点聚合错题，按 1 天 / 7 天的间隔提示复习。
struct ErrorBookView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var practiceLesson: Lesson?

    private struct ErrorGroup: Identifiable {
        let lesson: Lesson
        let total: Int
        let due: Int
        var id: String { lesson.id }
    }

    private var groups: [ErrorGroup] {
        let grouped = Dictionary(grouping: store.incorrectAttempts, by: \.lessonID)
        return grouped.compactMap { lessonID, attempts -> ErrorGroup? in
            guard let lesson = DomainCatalog.lesson(id: lessonID) else { return nil }
            let due = attempts.filter { ReviewScheduler.isDue($0) }.count
            return ErrorGroup(lesson: lesson, total: attempts.count, due: due)
        }
        .sorted { ($0.due, $0.total) > ($1.due, $1.total) }
    }

    private var dueTotal: Int { groups.reduce(0) { $0 + $1.due } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                if groups.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.seal",
                        title: "还没有错题",
                        message: "完成练习后，答错的题会自动按知识点汇总到这里。",
                        tint: Palette.success
                    )
                    .surfaceCard()
                } else {
                    HStack(spacing: 12) {
                        StatTile(value: "\(store.incorrectAttempts.count)", label: "错题总数", icon: "xmark.circle", tint: Palette.danger)
                        StatTile(value: "\(dueTotal)", label: "今天该复习", icon: "clock.badge.exclamationmark", tint: Palette.warning)
                        StatTile(value: "\(groups.count)", label: "涉及知识点", icon: "book.closed", tint: Palette.info)
                    }

                    VStack(alignment: .leading, spacing: Metric.stack) {
                        SectionHeader(title: "按知识点复习", subtitle: "答对后间隔拉长到 7 天，答错次日再来")
                        VStack(spacing: 10) {
                            ForEach(groups) { group in
                                Button { practiceLesson = group.lesson } label: {
                                    HStack(spacing: 13) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(AppFont.subhead)
                                            .foregroundStyle(Palette.warning)
                                            .frame(width: Metric.iconBox, height: Metric.iconBox)
                                            .background(Palette.warning.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(group.lesson.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                                            Text("\(group.lesson.ability) · 共 \(group.lesson.questions.count) 道练习")
                                                .font(AppFont.caption)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                        Spacer(minLength: 6)
                                        VStack(alignment: .trailing, spacing: 4) {
                                            if group.due > 0 {
                                                TagBadge(text: "\(group.due) 题到期", tint: Palette.warning)
                                            } else {
                                                TagBadge(text: "已排期", tint: Palette.textTertiary)
                                            }
                                            Text("错过 \(group.total) 题")
                                                .font(AppFont.label)
                                                .foregroundStyle(Palette.textTertiary)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(AppFont.captionStrong)
                                            .foregroundStyle(Palette.textTertiary)
                                    }
                                    .padding(Metric.fieldPadding)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Palette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.top, Metric.tight)
            .padding(.bottom, Metric.pageBottom)
        }
        .screenBackground()
        .navigationTitle("错题变身器")
        .sheet(item: $practiceLesson) { lesson in
            PracticeView(lesson: lesson) {}
                .environmentObject(store)
        }
    }
}

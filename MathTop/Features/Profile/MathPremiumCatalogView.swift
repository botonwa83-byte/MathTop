import SwiftUI

/// 进阶模块：把已有题库按训练方向重新组织，方便按专题推进。
struct MathPremiumCatalogView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("五个方向，各练一块短板")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Palette.textPrimary)
                    Text("每个模块都连接现有题库：先看清训练方向，再进入对应知识点逐题练。章节内的题量就是该方向的配套练习总量。")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .surfaceCard()

                ForEach(MathPremiumModule.all) { module in
                    NavigationLink { MathPremiumModuleView(module: module) } label: {
                        moduleCard(module)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.top, Metric.tight)
            .padding(.bottom, Metric.pageBottom)
            .mathReadableWidth()
        }
        .screenBackground()
        .navigationTitle("进阶模块")
    }

    private func moduleCard(_ module: MathPremiumModule) -> some View {
        let lessons = MathPremiumModule.lessons(for: module)
        let questions = lessons.reduce(0) { $0 + $1.questions.count }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: module.systemImage)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(module.tint)
                    .frame(width: Metric.iconBox, height: Metric.iconBox)
                    .background(module.tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                    Text(module.pitch)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(AppFont.captionStrong)
                    .foregroundStyle(Palette.textTertiary)
            }
            HStack(spacing: 6) {
                TagBadge(text: "\(lessons.count) 个知识点", tint: module.tint)
                TagBadge(text: "\(questions) 道练习", tint: Palette.textSecondary)
            }
        }
        .padding(Metric.fieldPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

/// 单个进阶模块下的知识点清单。
struct MathPremiumModuleView: View {
    let module: MathPremiumModule

    @EnvironmentObject private var store: LearningStore

    private var lessons: [Lesson] { MathPremiumModule.lessons(for: module) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metric.sectionGap) {
                HStack(spacing: 12) {
                    StatTile(value: "\(lessons.count)", label: "知识点", icon: "book.closed", tint: module.tint)
                    StatTile(
                        value: "\(lessons.reduce(0) { $0 + $1.questions.count })",
                        label: "配套练习",
                        icon: "list.number",
                        tint: Palette.accent
                    )
                    StatTile(
                        value: "\(lessons.filter { store.completedLessonIDs.contains($0.id) }.count)",
                        label: "已掌握",
                        icon: "checkmark.seal",
                        tint: Palette.success
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(module.pitch)
                        .font(AppFont.body)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .surfaceCard()

                VStack(alignment: .leading, spacing: Metric.stack) {
                    SectionHeader(title: "包含的知识点", subtitle: "点进去逐题练")
                    VStack(spacing: 10) {
                        ForEach(lessons) { lesson in
                            NavigationLink { SkillDetailView(lesson: lesson) } label: {
                                LessonRow(lesson: lesson, completed: store.completedLessonIDs.contains(lesson.id), showsSummary: false)
                            }
                            .buttonStyle(.plain)
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
        .navigationTitle(module.title)
    }
}

extension MathPremiumModule {
    var systemImage: String {
        switch id {
        case "contest": return "trophy"
        case "geometry-lab": return "cube.transparent"
        case "word-problems": return "text.badge.checkmark"
        case "review": return "arrow.uturn.backward.circle"
        case "assessment": return "chart.bar.doc.horizontal"
        default: return "sparkles"
        }
    }

    var tint: Color {
        switch id {
        case "contest": return Color(hex: 0xF26444)
        case "geometry-lab": return Color(hex: 0x4C8DF6)
        case "word-problems": return Color(hex: 0x2FA37C)
        case "review": return Color(hex: 0xE0912F)
        case "assessment": return Color(hex: 0x8A6BE2)
        default: return Palette.accent
        }
    }
}

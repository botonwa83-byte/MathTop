import SwiftUI

@main
struct MathTopApp: App {
    @StateObject private var store = LearningStore()
    var body: some Scene { WindowGroup { MainTabView().environmentObject(store) } }
}

let ink = Color(red: 0.09, green: 0.13, blue: 0.20)
let coral = Color(red: 0.96, green: 0.39, blue: 0.25)
let mint = Color(red: 0.55, green: 0.82, blue: 0.70)
let sky = Color(red: 0.36, green: 0.67, blue: 0.93)

struct MainTabView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("今日", systemImage: "sparkles") }.tag(0)
            PathView().tabItem { Label("能力地图", systemImage: "map") }.tag(1)
            NotebookView().tabItem { Label("知识本", systemImage: "book.closed") }.tag(2)
            ProfileView().tabItem { Label("我的", systemImage: "person.crop.circle") }.tag(3)
        }.tint(coral)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var showPractice = false
    @AppStorage("todayCompleted") private var todayCompleted = false
    @State private var selectedStage = "小学"
    private var stage: Stage { selectedStage == "初中" ? .junior : .primary }
    private var dailyPlan: DailyPlan { DailyPlanService.makePlan(stage: stage, store: store) }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("早上好，小探险家").font(.title2.bold()).foregroundStyle(ink)
                            Text("今天也来解锁一种新能力吧").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        ZStack { Circle().fill(mint.opacity(0.35)); Text("L3").font(.caption.bold()).foregroundStyle(ink) }.frame(width: 46, height: 46)
                    }
                    StagePicker(selection: $selectedStage)
                    HeroCard(title: dailyPlan.primary.title, summary: dailyPlan.primary.summary, completed: todayCompleted || store.completedLessonIDs.contains(dailyPlan.primary.id), action: { showPractice = true })
                    Text("今日能力组合").font(.title3.bold()).foregroundStyle(ink)
                    HStack(spacing: 12) {
                        SkillCard(icon: "function", title: "数感雷达", subtitle: "估算与找规律", color: coral, progress: 0.72)
                        SkillCard(icon: "character.book.closed", title: "句子魔法", subtitle: "一般现在时", color: sky, progress: 0.45)
                    }
                    Text("继续你的探索").font(.title3.bold()).foregroundStyle(ink)
                    if store.dueReviewCount > 0 {
                        NavigationLink { ErrorBookView() } label: { HStack { Image(systemName: "clock.badge.exclamationmark").foregroundStyle(coral); Text("有 \(store.dueReviewCount) 个知识点该复习了").font(.headline).foregroundStyle(ink); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(14).background(coral.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 16)) }
                    }
                    ContinueRow(icon: "arrow.triangle.2.circlepath", title: "错题变身器", detail: "把错题变成下一次的得分点", color: mint)
                    ContinueRow(icon: "headphones", title: "耳朵先知道", detail: "3 分钟英语听力热身", color: sky)
                }.padding(20)
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showPractice) { PracticeView(lesson: dailyPlan.primary) { todayCompleted = true; store.markLessonCompleted(dailyPlan.primary) } }
        }
    }
}

struct StagePicker: View {
    @Binding var selection: String
    var body: some View {
        HStack(spacing: 8) {
            ForEach(["小学", "初中"], id: \.self) { stage in
                Button { selection = stage } label: {
                    Text(stage).font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selection == stage ? ink : Color.white).foregroundStyle(selection == stage ? .white : ink).clipShape(Capsule())
                }
            }
        }.padding(4).background(Color.black.opacity(0.06)).clipShape(Capsule())
    }
}

struct HeroCard: View {
    let title: String
    let summary: String
    let completed: Bool
    let action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("TODAY'S QUEST").font(.caption.bold()).tracking(1.6).foregroundStyle(coral); Spacer(); Text("10 MIN").font(.caption.bold()).foregroundStyle(.secondary) }
            Text(completed ? "能力已解锁：\(title)" : "解锁：\(title)").font(.title.bold()).foregroundStyle(ink)
            Text(completed ? "今天的训练完成啦，明天继续点亮新的学习能力。" : summary)
                .font(.subheadline).foregroundStyle(ink.opacity(0.7)).fixedSize(horizontal: false, vertical: true)
            Button(action: action) { HStack { Text(completed ? "再练一次" : "开始今日训练"); Image(systemName: "arrow.right") }.font(.headline).foregroundStyle(.white).padding(.horizontal, 18).padding(.vertical, 12).background(ink).clipShape(Capsule()) }
        }.padding(22).background(LinearGradient(colors: [Color(red: 1, green: 0.87, blue: 0.69), Color(red: 1, green: 0.72, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct SkillCard: View {
    let icon, title, subtitle: String; let color: Color; let progress: Double
    var body: some View { VStack(alignment: .leading, spacing: 12) { Image(systemName: icon).font(.title2).foregroundStyle(color); Text(title).font(.headline).foregroundStyle(ink); Text(subtitle).font(.caption).foregroundStyle(.secondary); ProgressView(value: progress).tint(color) }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 18)) }
}

struct ContinueRow: View {
    let icon, title, detail: String; let color: Color
    var body: some View { HStack(spacing: 14) { Image(systemName: icon).font(.title3).foregroundStyle(ink).frame(width: 42, height: 42).background(color.opacity(0.45)).clipShape(Circle()); VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline).foregroundStyle(ink); Text(detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16)) }
}

struct PracticeView: View {
    let lesson: Lesson
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0; @State private var answer = ""
    private var question: Question? { lesson.questions.indices.contains(step) ? lesson.questions[step] : nil }
    let onComplete: () -> Void
    var body: some View { NavigationStack { VStack(alignment: .leading, spacing: 24) { HStack { Text(lesson.title).font(.title2.bold()); Spacer(); Text("\(min(step + 1, max(lesson.questions.count, 1))) / \(max(lesson.questions.count, 1))").font(.subheadline.bold()).foregroundStyle(.secondary) }; ProgressView(value: Double(step + 1), total: Double(max(lesson.questions.count, 1))).tint(coral); Text(question == nil ? "能力解锁完成！" : "先观察，再选择你的答案").font(.title3.bold()).foregroundStyle(ink); Spacer(); VStack(spacing: 12) { Text(question?.prompt ?? "你获得了：\(lesson.ability)").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(ink); if let question { ForEach(question.choices, id: \.id) { choice in Button { answer = choice.id } label: { Text(choice.text).font(.title3.bold()).frame(maxWidth: .infinity).padding().background(answer == choice.id ? mint : Color.white).foregroundStyle(ink).clipShape(RoundedRectangle(cornerRadius: 14)) } } } else { Image(systemName: "bolt.circle.fill").font(.system(size: 70)).foregroundStyle(coral) } }; Spacer(); Button { if let question { store.recordAttempt(questionID: question.id, lessonID: lesson.id, correct: answer == question.answer); answer = ""; step += 1 } else { onComplete(); dismiss() } } label: { Text(question == nil ? "收下能力" : "确认答案").font(.headline).frame(maxWidth: .infinity).padding().background(answer.isEmpty && question != nil ? Color.gray : ink).foregroundStyle(.white).clipShape(Capsule()) }.disabled(answer.isEmpty && question != nil) }.padding(22).background(Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea()).toolbar { ToolbarItem(placement: .topBarLeading) { Button("退出") { dismiss() } } } } }
}

struct PathView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var stage: Stage = .primary
    var body: some View {
        NavigationStack { List {
            Section { Picker("学段", selection: $stage) { ForEach(Stage.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented) }
            ForEach(Array(Dictionary(grouping: MathContent.lessons(for: stage), by: { $0.ability }).sorted(by: { $0.key < $1.key })), id: \.key) { group in
                Section { ForEach(group.value) { row($0) } } header: { HStack { Text(group.key); Spacer(); Text("\(group.value.filter { store.completedLessonIDs.contains($0.id) }.count)/\(group.value.count)").font(.caption).foregroundStyle(.secondary) } }
            }
        }.navigationTitle("能力地图") }
    }
    @ViewBuilder private func row(_ lesson: Lesson) -> some View {
        NavigationLink { SkillDetailView(title: lesson.title, detail: lesson.summary) } label: {
            HStack { Image(systemName: store.completedLessonIDs.contains(lesson.id) ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(store.completedLessonIDs.contains(lesson.id) ? .green : coral); VStack(alignment: .leading) { Text(lesson.ability).font(.headline); Text("\(lesson.minutes) 分钟 · \(lesson.title)").font(.caption).foregroundStyle(.secondary) }; Spacer(); if store.completedLessonIDs.contains(lesson.id) { Text("已掌握").font(.caption.bold()).foregroundStyle(.green) } }
        }
    }
}
struct NotebookView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View { NavigationStack { List { NavigationLink { CurriculumListView(stage: .primary) } label: { HStack { Label("小学数学知识点", systemImage: "number.square"); Spacer(); Text("\(MathContent.lessons(for: .primary).count)").foregroundStyle(.secondary) } }; NavigationLink { CurriculumListView(stage: .junior) } label: { HStack { Label("初中数学知识点", systemImage: "function"); Spacer(); Text("\(MathContent.lessons(for: .junior).count)").foregroundStyle(.secondary) } }; NavigationLink { ErrorBookView() } label: { HStack { Label("错题变身器", systemImage: "arrow.triangle.2.circlepath"); Spacer(); Text("\(store.incorrectAttempts.count)").foregroundStyle(.secondary) } }; Label("我的收藏", systemImage: "bookmark") }.navigationTitle("知识本") } }
}

struct CurriculumListView: View {
    let stage: Stage
    @EnvironmentObject private var store: LearningStore
    var body: some View {
        List {
            let lessons = MathContent.lessons(for: stage)
            Section("共 \(lessons.count) 个知识点") {
                ForEach(lessons) { lesson in
                    NavigationLink { SkillDetailView(title: lesson.title, detail: lesson.summary) } label: {
                        HStack { Image(systemName: store.completedLessonIDs.contains(lesson.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(store.completedLessonIDs.contains(lesson.id) ? .green : coral); VStack(alignment: .leading) { Text(lesson.title).font(.headline); Text(lesson.ability).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("\(lesson.questions.count)题").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
        }.navigationTitle(stage.rawValue + "数学")
    }
}

struct ErrorBookView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View { List { if store.incorrectAttempts.isEmpty { VStack(spacing: 12) { Image(systemName: "checkmark.seal").font(.largeTitle).foregroundStyle(.green); Text("还没有错题").font(.headline); Text("完成练习后，答错的题会自动出现在这里。").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 40) } else { ForEach(store.incorrectAttempts) { attempt in HStack { Image(systemName: "arrow.uturn.backward.circle").foregroundStyle(coral); VStack(alignment: .leading) { Text("知识点练习").font(.headline); Text(attempt.date, style: .date).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("待复习").font(.caption).foregroundStyle(coral) } } } }.navigationTitle("错题变身器") }
}
struct SkillDetailView: View { let title: String; let detail: String; var body: some View { VStack(alignment: .leading, spacing: 18) { Text(title).font(.largeTitle.bold()); Text(detail).font(.title3).foregroundStyle(.secondary); Text("从一个小任务开始，练会后再挑战下一格。").font(.body); Spacer(); Button("开始练习") {}.font(.headline).frame(maxWidth: .infinity).padding().background(ink).foregroundStyle(.white).clipShape(Capsule()) }.padding(24).navigationTitle("能力详情") } }
struct KnowledgeDetailView: View { let title: String; var body: some View { List { Section("今天复习") { Label("3 个新知识点", systemImage: "sparkles"); Label("5 道轻练习", systemImage: "checkmark.circle") }; Section("掌握进度") { ProgressView(value: 0.62).tint(coral) } }.navigationTitle(title) } }
struct ProfileView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View { NavigationStack { VStack(spacing: 18) { Circle().fill(mint).frame(width: 86, height: 86).overlay(Text("小探险家").font(.caption.bold()).foregroundStyle(ink)); Text("小探险家").font(.title2.bold()); Text("数学能力成长档案").font(.subheadline).foregroundStyle(.secondary); HStack(spacing: 12) { stat("\(store.completedLessonIDs.count)", "已解锁"); stat("\(MathContent.lessons.count)", "知识点"); stat("\(store.attempts.count)", "已练题") }.padding(.top, 10); ProgressView(value: Double(store.completedLessonIDs.count), total: Double(max(MathContent.lessons.count, 1))).tint(coral); Text("继续从能力地图选择一个知识点，完成今日 10 分钟训练。").font(.caption).foregroundStyle(.secondary); Spacer() }.padding(24).navigationTitle("我的") } }
    private func stat(_ value: String, _ label: String) -> some View { VStack { Text(value).font(.title3.bold()).foregroundStyle(coral); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14)) }
}

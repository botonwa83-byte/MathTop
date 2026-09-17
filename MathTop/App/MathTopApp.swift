import SwiftUI

@main
struct MathTopApp: App {
    @StateObject private var store = LearningStore()
    @StateObject private var purchase = MathPurchaseManager.shared
    var body: some Scene {
        WindowGroup {
            MathRootView()
                .environmentObject(store)
                .environmentObject(purchase)
        }
    }
}

struct MathRootView: View {
    @State private var entered = LaunchOptions.skipsPromo

    var body: some View {
        Group {
            if entered {
                DebugScreenHost {
                    MainTabView()
                }
            } else {
                MathPromoView { withAnimation(.easeInOut(duration: 0.25)) { entered = true } }
            }
        }
    }
}

struct MainTabView: View {
    @State private var tab = LaunchOptions.initialTab

    var body: some View {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("今日", systemImage: "sparkles") }.tag(0)
            PathView().tabItem { Label("能力地图", systemImage: "map") }.tag(1)
            NotebookView().tabItem { Label("知识本", systemImage: "book.closed") }.tag(2)
            ProfileView().tabItem { Label("我的", systemImage: "person.crop.circle") }.tag(3)
        }
        .tint(Palette.accent)
    }
}

/// 仅用于自动化截图核验：带 `-screen <name>` 启动时直接打开对应二级页面。
struct DebugScreenHost<Content: View>: View {
    @ViewBuilder let content: Content

    private var sampleLesson: Lesson { MathContent.lessons(for: .primary).first { $0.id == "p-four" } ?? MathContent.lessons[0] }

    var body: some View {
        switch LaunchOptions.debugScreen {
        case "practice":
            PracticeView(lesson: sampleLesson) {}
        case "detail":
            NavigationStack { SkillDetailView(lesson: sampleLesson) }
        case "simulation":
            NavigationStack { SimulationCatalogView() }
        case "errors":
            NavigationStack { ErrorBookView() }
        case "growth":
            NavigationStack { GrowthSummaryView() }
        case "premium":
            NavigationStack { MathPremiumCatalogView() }
        case "domains":
            NavigationStack { DomainListView(stage: .primary) }
        case "favorites":
            NavigationStack { FavoriteListView() }
        default:
            content
        }
    }
}

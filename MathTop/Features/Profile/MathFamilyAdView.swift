import SwiftUI

// MARK: - Top King 同门软件推荐位（首页广告页与解锁页共用）
//
// 广告位目的：让用户知道这是一整套同厂出品的学习工具——
// 同一套「会拆题、记错因、给下一步」的引擎，攻克一科，另外两科直接上手。
// 链接先指向各自官网（App Store 上架后把 url 换成 itms-apps://apps.apple.com/cn/app/idXXXX 即可）。

enum MathFamilyApp: String, CaseIterable, Identifiable {
    case chin
    case math
    case eng

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chin: return "语文登顶 ChinTop"
        case .math: return "数学登顶 MathTop"
        case .eng: return "英语登顶 EngTop"
        }
    }

    var pitch: String {
        switch self {
        case .chin: return "证据表达力：阅读、文言、诗词、作文，写得出采分点"
        case .math: return "建模推理力：把应用题拆成步骤，压轴题也敢下手"
        case .eng: return "考点导航力：语法、完形、读后续写，先补最容易丢分的那块"
        }
    }

    var icon: String {
        switch self {
        case .chin: return "book.closed.fill"
        case .math: return "function"
        case .eng: return "character.book.closed.fill"
        }
    }

    var tint: Color {
        switch self {
        case .chin: return .pink
        case .math: return Palette.accent
        case .eng: return Palette.info
        }
    }

    var url: URL {
        switch self {
        case .chin: return URL(string: "https://botonwa83-byte.github.io/ChinTop/")!
        case .math: return MathLegal.site
        case .eng: return URL(string: "https://botonwa83-byte.github.io/EngTop/")!
        }
    }
}

/// 同门三件套推荐位。`onDark` 用于首页广告页这类深色底场景。
struct MathFamilyAdSection: View {
    var current: MathFamilyApp = .math
    var onDark: Bool = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.warning)
                Text("Top King 出品 · 同门三件套")
                    .font(AppFont.label)
                    .foregroundStyle(secondaryText)
            }
            ForEach(MathFamilyApp.allCases) { app in
                MathFamilyAdRow(app: app, isCurrent: app == current, onDark: onDark) { openURL(app.url) }
            }
            Text("同一套学习引擎：会拆题、记错因、给下一步。攻克一科，另外两科直接上手。")
                .font(AppFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metric.cardPadding)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous))
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Palette.surface }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Palette.textSecondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Palette.textTertiary }
}

private struct MathFamilyAdRow: View {
    let app: MathFamilyApp
    let isCurrent: Bool
    let onDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metric.stack) {
                Image(systemName: app.icon)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(app.tint, in: RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(app.title)
                            .font(AppFont.cardTitle)
                            .foregroundStyle(onDark ? .white : Palette.textPrimary)
                        if isCurrent {
                            Text("使用中")
                                .font(AppFont.label)
                                .foregroundStyle(Palette.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Palette.success.opacity(0.14), in: Capsule())
                        }
                    }
                    Text(app.pitch)
                        .font(AppFont.caption)
                        .foregroundStyle(onDark ? Color.white.opacity(0.65) : Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(AppFont.caption)
                    .foregroundStyle(onDark ? Color.white.opacity(0.45) : Palette.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("了解 \(app.title)")
    }
}

// MARK: - 一杯奶茶价说服卡

/// 价格锚点：把一次买断翻译成「一杯奶茶」，并给出「先逛逛再决定」的退路，降低决策压力。
struct MathMilkTeaPitchCard: View {
    var onDark: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.warning)
                Text("一杯奶茶 vs 一次解锁")
                    .font(AppFont.label)
                    .foregroundStyle(secondaryText)
            }
            Text("一杯奶茶的钱，换掉一整年的「这题我又卡住了」")
                .font(AppFont.sectionTitle)
                .foregroundStyle(onDark ? .white : Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("奶茶两小时见底；一次解锁，陪你刷到毕业——每道不会的题，都有人拆给你看。")
                .font(AppFont.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Metric.tight) {
                pitchRow("奶茶：一口的快乐，两个小时就忘", tint: Palette.textTertiary)
                pitchRow("解锁：一套拆题的思路，用到毕业", tint: Palette.success)
                pitchRow("今天少喝一杯奶茶，明天多拿下一次压轴题", tint: Palette.accent)
            }
            Text("免费部分永远免费：先练 3 题再决定，想通了回来，价格不变。")
                .font(AppFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metric.cardPadding)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous))
    }

    private func pitchRow(_ text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: Metric.tight) {
            Circle().fill(tint).frame(width: 6, height: 6).padding(.top, 6)
            Text(text)
                .font(AppFont.body)
                .foregroundStyle(onDark ? Color.white.opacity(0.85) : Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Palette.surface }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Palette.textSecondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Palette.textTertiary }
}

// MARK: - 「要不要现在解锁」询问卡

/// 给一个明确的「是 / 否」：想买就买，不想买就先逛——免费内容不缩水，随时可以回来。
struct MathUnlockAskCard: View {
    let price: String
    var onDark: Bool = false
    let onUnlock: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.stack) {
            Text("要不要用一杯奶茶的价格，解锁整个 MathTop？")
                .font(AppFont.sectionTitle)
                .foregroundStyle(onDark ? .white : Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("解锁后：全部知识点完整题组 + 仿真全三批 + 五个进阶模块，一次买断，永久使用。")
                .font(AppFont.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onUnlock) {
                Label("好，一杯奶茶换一整年底气  \(price)", systemImage: "lock.open.fill")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Metric.stack + 2)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
            }
            .buttonStyle(.plain)
            Button(action: onBrowse) {
                Text("先逛逛，等会儿再决定")
                    .font(AppFont.body)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            Text("先浏览也行：免费内容不缩水，想好了随时回来解锁。")
                .font(AppFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metric.cardPadding)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous))
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Palette.surface }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Palette.textSecondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Palette.textTertiary }
}

import SwiftUI

// MARK: - 色板
//
// 全 App 只允许通过这里的语义色取色，禁止在页面里直接写 Color(red:green:blue:)。
// 基础色（ink / coral / mint / sky）保留为顶层常量，兼容既有代码。

/// 基础品牌色。
let ink = Color(hex: 0x16202E)
let coral = Color(hex: 0xF26444)
let mint = Color(hex: 0x76C8AE)
let sky = Color(hex: 0x5C9FEE)

/// 语义色板：页面背景、卡片、描边、文字层级、状态色。
enum Palette {
    /// 页面背景（暖白，减少长时间阅读的刺眼感）。
    static let paper = Color(hex: 0xF7F7F4)
    /// 卡片背景。
    static let surface = Color.white
    /// 次级填充（筛选器胶囊底色、图标托底）。
    static let fill = Color(hex: 0xEFEFEA)
    /// 描边。
    static let line = Color(hex: 0xE4E4DE)

    /// 正文主色。
    static let textPrimary = ink
    /// 正文次级色（说明、描述）。
    static let textSecondary = Color(hex: 0x6D7684)
    /// 弱化文字（辅助标注、单位）。
    static let textTertiary = Color(hex: 0x9AA2AE)

    /// 主行动色（开始学习、确认答案）。
    static let action = ink
    /// 强调色（进度、关键数据）。
    static let accent = coral
    /// 成功 / 已完成。
    static let success = Color(hex: 0x3FA37A)
    /// 警示 / 待复习。
    static let warning = Color(hex: 0xE0912F)
    /// 信息。
    static let info = sky
    /// 错误 / 错题。
    static let danger = Color(hex: 0xD6453C)
    /// 连续学习（火苗）。
    static let streak = Color(hex: 0xF08A24)
}

/// 五维能力的专属配色，避免各页面各写一套。
extension Capability {
    var tint: Color {
        switch self {
        case .numberSense: return Color(hex: 0x4C8DF6)
        case .modeling: return Color(hex: 0xF26444)
        case .reasoning: return Color(hex: 0x8A6BE2)
        case .expression: return Color(hex: 0x2FA37C)
        case .focusReflection: return Color(hex: 0xE0912F)
        }
    }
}

extension Stage {
    var tint: Color {
        switch self {
        case .primary: return Color(hex: 0x4C8DF6)
        case .junior: return Color(hex: 0xF26444)
        }
    }

    var systemImage: String {
        switch self {
        case .primary: return "number.square.fill"
        case .junior: return "function"
        }
    }

    var subtitle: String {
        switch self {
        case .primary: return "1–6 年级 · 数与运算、图形、统计"
        case .junior: return "7–9 年级 · 代数、函数、几何、概率"
        }
    }
}

extension CapabilityTrend {
    var tint: Color {
        switch self {
        case .rising: return Palette.success
        case .steady: return Palette.textTertiary
        case .needsAttention: return Palette.warning
        }
    }

    var systemImage: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .steady: return "arrow.right"
        case .needsAttention: return "exclamationmark"
        }
    }
}

extension LearningMode {
    var systemImage: String {
        switch self {
        case .understand: return "eye"
        case .practice: return "pencil.and.outline"
        case .transfer: return "arrow.triangle.branch"
        case .reflect: return "text.bubble"
        case .focus: return "timer"
        }
    }

    var tint: Color {
        switch self {
        case .understand: return Color(hex: 0x4C8DF6)
        case .practice: return Color(hex: 0xF26444)
        case .transfer: return Color(hex: 0x8A6BE2)
        case .reflect: return Color(hex: 0x2FA37C)
        case .focus: return Color(hex: 0xE0912F)
        }
    }
}

// MARK: - 尺寸令牌

enum Metric {
    /// 页面左右统一留白。
    static let gutter: CGFloat = 20
    /// 卡片内边距。
    static let cardPadding: CGFloat = 18
    /// 区块之间的间距。
    static let sectionGap: CGFloat = 26
    /// 同一区块内元素间距。
    static let stack: CGFloat = 12
    /// 紧凑间距。
    static let tight: CGFloat = 8

    static let radiusCard: CGFloat = 20
    static let radiusTile: CGFloat = 16
    static let radiusChip: CGFloat = 10
    static let radiusPill: CGFloat = 999

    static let iconBox: CGFloat = 42
    static let tapTarget: CGFloat = 44
}

// MARK: - 字号层级
//
// 只允许用这几档，避免页面里出现 .caption / .headline / 自定义 size 混用。

enum AppFont {
    /// 大屏标题（页面主标题）。
    static let screenTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    /// 区块标题。
    static let sectionTitle = Font.system(size: 18, weight: .bold)
    /// 卡片标题。
    static let cardTitle = Font.system(size: 16, weight: .semibold)
    /// 正文。
    static let body = Font.system(size: 15)
    /// 说明文字。
    static let caption = Font.system(size: 13)
    /// 辅助标注（全大写、加字距时用）。
    static let label = Font.system(size: 11, weight: .semibold)
    /// 数据大字。
    static let metric = Font.system(size: 22, weight: .bold, design: .rounded)
    /// 题面 / 选项。
    static let question = Font.system(size: 20, weight: .semibold, design: .rounded)
}

// MARK: - 工具

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension View {
    /// 统一卡片外观：白底、圆角、细描边、极轻阴影。
    func surfaceCard(radius: CGFloat = Metric.radiusCard, padding: CGFloat = Metric.cardPadding) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.line, lineWidth: 1)
            )
            .shadow(color: ink.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    /// 页面统一背景。
    func screenBackground() -> some View {
        self.background(Palette.paper.ignoresSafeArea())
    }
}

// MARK: - iPad 可读宽度

/// 大屏（iPad / 横屏）下限制内容最大宽度并居中，iPhone 不受影响。
/// 所有竖向滚动页面的内容都应套一层，避免 iPad 上文字行长失控。
struct MathReadableWidthModifier: ViewModifier {
    var maxWidth: CGFloat = 720

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    func mathReadableWidth(_ maxWidth: CGFloat = 720) -> some View {
        modifier(MathReadableWidthModifier(maxWidth: maxWidth))
    }
}

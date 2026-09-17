import SwiftUI

// MARK: - 区块标题

/// 统一的区块标题：左侧标题 + 可选副标题，右侧可选补充信息。
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.sectionTitle).foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle).font(AppFont.caption).foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing).font(AppFont.caption.bold()).foregroundStyle(Palette.textTertiary)
            }
        }
    }
}

// MARK: - 数据小卡

/// 关键数据小卡：一个大数字 + 一行说明，可带图标。
struct StatTile: View {
    let value: String
    let label: String
    var icon: String? = nil
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(AppFont.footnote)
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(AppFont.metric)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, Metric.fieldPadding)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }
}

/// 标签胶囊。
struct TagBadge: View {
    let text: String
    var tint: Color = Palette.accent
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(AppFont.badge)
            }
            Text(text).font(AppFont.label)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - 进度

/// 环形进度。
struct ProgressRing: View {
    let value: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 7
    var tint: Color = Palette.accent
    var caption: String? = nil

    var body: some View {
        ZStack {
            Circle().stroke(Palette.fill, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(value, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int((min(max(value, 0), 1)) * 100))%")
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                if let caption {
                    Text(caption)
                        .font(.system(size: size * 0.15))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// 能力条：能力名 + 掌握度进度 + 趋势标记。
struct CapabilityBar: View {
    let capability: Capability
    let mastery: Double
    let trend: CapabilityTrend
    var practiceCount: Int? = nil
    var showsBlurb = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: capability.systemImage)
                    .font(AppFont.captionStrong)
                    .foregroundStyle(capability.tint)
                    .frame(width: 24, height: 24)
                    .background(capability.tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Metric.radiusDot, style: .continuous))
                Text(capability.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 6)
                Text("\(Int(mastery * 100))%")
                    .font(AppFont.caption.bold())
                    .foregroundStyle(Palette.textSecondary)
                Image(systemName: trend.systemImage)
                    .font(AppFont.badge)
                    .foregroundStyle(trend.tint)
            }
            ProgressView(value: max(0.001, min(mastery, 1)))
                .tint(capability.tint)
            if showsBlurb {
                Text(capability.blurb).font(AppFont.caption).foregroundStyle(Palette.textTertiary)
            } else if let practiceCount, practiceCount > 0 {
                Text("近 30 天练习 \(practiceCount) 次").font(AppFont.caption).foregroundStyle(Palette.textTertiary)
            }
        }
    }
}

/// 近 7 天学习次数柱状条。
struct MiniBarChart: View {
    let values: [Int]
    var tint: Color = Palette.accent

    private var maxValue: Int { max(values.max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: Metric.radiusHairline, style: .continuous)
                        .fill(value == 0 ? Palette.fill : tint.opacity(0.35 + 0.65 * Double(value) / Double(maxValue)))
                        .frame(height: max(6, 34 * CGFloat(value) / CGFloat(maxValue)))
                    Text("\(value)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - 按钮与选择

/// 主行动按钮（胶囊）。
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Palette.action
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(AppFont.cardTitle)
                if let icon { Image(systemName: icon).font(AppFont.subheadBold) }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Metric.tapTarget + 4)
            .foregroundStyle(.white)
            .background(enabled ? tint : Palette.textTertiary)
            .clipShape(Capsule())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

/// 次级按钮（描边）。
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(AppFont.footnote) }
                Text(title).font(AppFont.bodyStrong)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Metric.tapTarget)
            .foregroundStyle(Palette.textPrimary)
            .background(Palette.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// 可选择胶囊。
struct ChipButton: View {
    let title: String
    let selected: Bool
    var tint: Color = Palette.action
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.subhead)
                .foregroundStyle(selected ? .white : Palette.textSecondary)
                .padding(.horizontal, Metric.fieldPadding)
                .frame(height: 36)
                .background(selected ? tint : Palette.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? .clear : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// 学段分段选择器。
struct StageSegmentedControl: View {
    @Binding var stage: Stage

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Stage.allCases, id: \.self) { item in
                Button { stage = item } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.systemImage).font(AppFont.captionStrong)
                        Text(item.rawValue).font(AppFont.subhead)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .foregroundStyle(stage == item ? .white : Palette.textSecondary)
                    .background(stage == item ? item.tint : .clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Metric.hairline)
        .background(Palette.fill)
        .clipShape(Capsule())
    }
}

// MARK: - 行与列表项

/// 可点击的功能入口行。
struct ActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var tint: Color = Palette.accent
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(AppFont.bodyStrong)
                .foregroundStyle(tint)
                .frame(width: Metric.iconBox, height: Metric.iconBox)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Metric.radiusField, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let trailingText {
                Text(trailingText).font(AppFont.caption.bold()).foregroundStyle(Palette.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(AppFont.captionStrong)
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Metric.fieldPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }
}

/// 任务清单行（理解 / 练习 / 迁移 / 复盘），显示完成状态。
struct ChecklistRow: View {
    let mode: LearningMode
    let title: String
    let minutes: Int
    let completed: Bool

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(completed ? Palette.success : mode.tint.opacity(0.14))
                    .frame(width: 30, height: 30)
                Image(systemName: completed ? "checkmark" : mode.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(completed ? .white : mode.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(completed ? Palette.textSecondary : Palette.textPrimary)
                    .strikethrough(completed, color: Palette.textTertiary)
                Text("\(mode.title) · \(minutes) 分钟").font(AppFont.caption).foregroundStyle(Palette.textTertiary)
            }
            Spacer(minLength: 6)
            if completed {
                Text("已完成").font(AppFont.label).foregroundStyle(Palette.success)
            }
        }
    }
}

/// 提示条（如“有 N 个知识点该复习了”）。
struct NoticeBanner: View {
    let icon: String
    let title: String
    var message: String? = nil
    var tint: Color = Palette.warning

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(AppFont.bodyStrong)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                if let message {
                    Text(message).font(AppFont.caption).foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right").font(AppFont.label).foregroundStyle(Palette.textTertiary)
        }
        .padding(Metric.fieldPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous).stroke(tint.opacity(0.22), lineWidth: 1))
    }
}

/// 空状态。
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var tint: Color = Palette.success

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(tint)
            Text(title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
            Text(message)
                .font(AppFont.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metric.heroGap)
        .padding(.horizontal, 20)
    }
}

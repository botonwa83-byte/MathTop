import Foundation

/// 启动参数开关。
///
/// 只服务于自动化核验（截图与回归检查）：正常启动不带任何参数，行为完全不变。
/// - `-skipPromo`：跳过引导页，直接进入主界面。
/// - `-tab <0-3>`：指定启动时选中的 Tab。
/// - `-screen <name>`：直接打开某个二级页面，便于逐屏截图核对版式。
enum LaunchOptions {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var skipsPromo: Bool { arguments.contains("-skipPromo") }

    static var initialTab: Int {
        guard let index = arguments.firstIndex(of: "-tab"),
              arguments.indices.contains(index + 1),
              let value = Int(arguments[index + 1]) else { return 0 }
        return value
    }

    static var debugScreen: String? {
        guard let index = arguments.firstIndex(of: "-screen"),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    /// 首页滚动定位目标（区块 id），用于截图核对下半屏内容。
    static var scrollTarget: String? {
        guard let index = arguments.firstIndex(of: "-scroll"),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

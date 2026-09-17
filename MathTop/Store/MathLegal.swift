import SwiftUI

// MARK: - 上线合规入口（GitHub Pages 托管，付费墙与「我的」页共用同一组链接）

enum MathLegal {
    static let site = URL(string: "https://botonwa83-byte.github.io/MathTop/")!
    static let termsURL = URL(string: "https://botonwa83-byte.github.io/MathTop/terms.html")!
    static let privacyURL = URL(string: "https://botonwa83-byte.github.io/MathTop/privacy.html")!
    static let supportURL = URL(string: "https://botonwa83-byte.github.io/MathTop/support.html")!
}

/// 协议与隐私入口：付费墙底部 +「我的」页「关于与协议」共用。
struct MathLegalLinksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link("用户协议", destination: MathLegal.termsURL)
            Link("隐私政策", destination: MathLegal.privacyURL)
            Link("技术支持", destination: MathLegal.supportURL)
        }
        .font(AppFont.caption)
    }
}

import SwiftUI

struct MathPromoView: View {
    let onEnter: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(colors: [ink, Color(red: 0.16, green: 0.24, blue: 0.34)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image(systemName: "function").font(.system(size: 46, weight: .bold)).foregroundStyle(mint).padding(24).background(mint.opacity(0.16), in: Circle()).padding(.top, 42)
                    Text("MATH TOP").font(.system(size: 30, weight: .heavy, design: .rounded)).tracking(3).foregroundStyle(.white)
                    Text("数 学 登 顶 · 能 力 导 航").font(.subheadline).tracking(2).foregroundStyle(.white.opacity(0.65))
                    Text("赋予学生一项能力：建模推理力").font(.headline).multilineTextAlignment(.center).foregroundStyle(mint).padding(.top, 12)
                    Text("把文字情境变成数量关系，把陌生题拆成可执行步骤，从基础计算迁移到压轴问题。").font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
                    ForEach([("map", "知识地图：数与式、函数、几何、统计全覆盖"), ("target", "能力靶场：每题都有方法、步骤与解析"), ("arrow.triangle.2.circlepath", "错题复盘：按错误类型安排间隔复习"), ("chart.xyaxis.line", "提分报告：阶段测评与薄弱点建议")], id: \.1) { item in
                        Label(item.1, systemImage: item.0).frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                    }
                    HStack { stat("\(MathContent.lessons.count)", "知识点"); Divider().frame(height: 28); stat("\(MathContent.lessons.reduce(0) { $0 + $1.questions.count })", "练习题"); Divider().frame(height: 28); stat("5", "进阶模块") }.padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    Text("学习能力闭环：看懂情境 → 建立模型 → 推导验证 → 迁移复盘").font(.caption).foregroundStyle(mint).multilineTextAlignment(.center).padding(.vertical, 8)
                    Text("MathTop · 数学登顶  v1.0.0\n© 2026 Top King. All rights reserved.").font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.45)).padding(.vertical, 18)
                    Button(action: onEnter) { Label("开启数学登顶之旅", systemImage: "arrow.right").font(.headline).frame(maxWidth: .infinity).padding().background(coral, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white) }.padding(.bottom, 24)
                }.padding(.horizontal, 24).frame(maxWidth: 600)
            }
        }
    }
    private func stat(_ value: String, _ label: String) -> some View { VStack { Text(value).font(.headline).foregroundStyle(mint); Text(label).font(.caption).foregroundStyle(.white.opacity(0.6)) }.frame(maxWidth: .infinity) }
}

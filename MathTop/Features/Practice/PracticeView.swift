import SwiftUI

// MARK: 临时性能探针（测量后删除）
final class FrameProbe {
    static let shared = FrameProbe()
    private var link: CADisplayLink?
    private var lastFrame: CFAbsoluteTime = 0
    private var sum: Double = 0
    private var peak: Double = 0
    private var count = 0

    func start() {
        guard link == nil else { return }
        link = CADisplayLink(target: self, selector: #selector(fire))
        link?.add(to: .main, forMode: .common)
    }

    @objc private func fire() {
        let now = CFAbsoluteTimeGetCurrent()
        if PerfProbe.lastTapFrame > 0 {
            PerfProbe.log(String(format: "tap -> frame %.1f ms", (now - PerfProbe.lastTapFrame) * 1000))
            PerfProbe.lastTapFrame = 0
        }
        if lastFrame > 0 {
            let delta = (now - lastFrame) * 1000
            sum += delta
            if delta > peak { peak = delta }
            count += 1
            if count >= 60 {
                PerfProbe.log(String(format: "frames avg %.1f ms, peak %.1f ms", sum / Double(count), peak))
                sum = 0; peak = 0; count = 0
            }
        }
        lastFrame = now
    }
}

enum PerfProbe {
    static var lastTap: CFAbsoluteTime = 0
    static var lastTapFrame: CFAbsoluteTime = 0
    static var marks: [String: CFAbsoluteTime] = [:]

    static func mark() {
        lastTap = CFAbsoluteTimeGetCurrent()
        lastTapFrame = lastTap
    }

    /// 记录某个视图两次 body 求值之间的间隔，用来判断它是否被连带重算。
    static func tick(_ name: String) {
        let now = CFAbsoluteTimeGetCurrent()
        if let last = marks[name] {
            log("\(name) body +\(String(format: "%.1f", (now - last) * 1000)) ms")
        }
        marks[name] = now
    }
    static func log(_ line: String) {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("perf.log") else { return }
        let text = line + "\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(text.utf8))
            try? handle.close()
        } else {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

/// 练习页。
///
/// 三种用法：
/// 1. 知识点练习：`PracticeView(lesson:)`，按 `chunkSize` 分批推进（默认每批 5 题）；
/// 2. 今日任务包：额外传入 `session` / `activity`，完成后把结果写回能力成长；
/// 3. 仿真题集中训练：`chunkSize: nil`，一次连续做完。
struct PracticeView: View {
    let lesson: Lesson
    var session: StudySession? = nil
    var activity: LearningActivity? = nil
    var chunkSize: Int? = LessonPracticeFactory.batchSize
    /// 仿真题批次在外层已按批次判定过锁，这里传 true 走完整题量，
    /// 否则会被免费档（每知识点前 3 题）截断，导致「第 1 批 34 题免费」名不副实。
    var fullAccess: Bool = false
    let onComplete: () -> Void

    @EnvironmentObject private var store: LearningStore
    // 单例注入：付费状态是全局的，sheet / NavigationLink 都不需要再传 env
    @ObservedObject private var purchase = MathPurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var chunkIndex = 0
    @State private var step = 0
    @State private var selectedChoiceID: String?
    @State private var submitted = false
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var showPaywall = false

    /// 免费档：未解锁时只开放每个知识点前 N 题（内购划线，改动需同步 testFreeTierPolicy）。
    private var pool: [Question] {
        fullAccess ? lesson.questions : purchase.availableQuestions(for: lesson)
    }

    private var chunkCount: Int {
        guard let chunkSize, chunkSize > 0, !pool.isEmpty else { return 1 }
        return max(1, Int(ceil(Double(pool.count) / Double(chunkSize))))
    }

    private var questions: [Question] {
        guard let chunkSize, chunkSize > 0 else { return pool }
        return Array(pool.dropFirst(chunkIndex * chunkSize).prefix(chunkSize))
    }

    private var question: Question? { questions.indices.contains(step) ? questions[step] : nil }
    private var isLastChunk: Bool { chunkIndex >= chunkCount - 1 }
    private var isLastStep: Bool { step >= questions.count }
    private var accuracy: Double { answeredCount == 0 ? 1 : Double(correctCount) / Double(answeredCount) }

    var body: some View {
        if PerfProbe.lastTap > 0 {
            PerfProbe.log(String(format: "render latency %.1f ms (chunk %d step %d submitted %d, attempts %d)", (CFAbsoluteTimeGetCurrent() - PerfProbe.lastTap) * 1000, chunkIndex, step, submitted ? 1 : 0, store.attempts.count))
            PerfProbe.lastTap = 0
        }
        return NavigationStack {
            VStack(spacing: 0) {
                header
                progressBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if let question {
                            questionBlock(question)
                        } else {
                            chunkSummary
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 18)
                    .padding(.bottom, Metric.blockGap)
                    .mathReadableWidth()
                }
                bottomBar
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { store.notifyDataChanged() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }.foregroundStyle(Palette.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(lesson.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                }
            }
            .sheet(isPresented: $showPaywall) { MathPaywallView() }
            .onAppear { FrameProbe.shared.start() }
            .onReceive(Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()) { _ in
                guard ProcessInfo.processInfo.arguments.contains("-perfPractice") else { return }
                if !submitted { selectedChoiceID = questions.first?.choices.first?.id }
                advance()
            }
        }
    }

    // MARK: 头部

    private var header: some View {
        HStack(spacing: 8) {
            TagBadge(text: lesson.ability, tint: lesson.stage.tint)
            TagBadge(text: "共 \(pool.count) 题", tint: Palette.textSecondary)
            if chunkCount > 1 {
                TagBadge(text: "第 \(chunkIndex + 1)/\(chunkCount) 批", tint: Palette.info, icon: "square.stack.3d.up")
            }
            Spacer()
            Text("\(min(step + 1, questions.count)) / \(questions.count)")
                .font(AppFont.caption.bold())
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, Metric.tight)
    }

    private var progressBar: some View {
        ProgressView(value: Double(min(step, questions.count)), total: Double(max(questions.count, 1)))
            .tint(Palette.accent)
            .padding(.horizontal, Metric.gutter)
            .padding(.top, Metric.chipGap)
    }

    // MARK: 题目

    @ViewBuilder
    private func questionBlock(_ question: Question) -> some View {
        Text(question.prompt)
            .font(AppFont.question)
            .foregroundStyle(Palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, Metric.cardPadding)
            .padding(.horizontal, Metric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous).stroke(Palette.line, lineWidth: 1))

        VStack(spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.element.id) { index, choice in
                choiceRow(question: question, choice: choice, index: index)
            }
        }

        if submitted {
            explanationBlock(question)
        }
    }

    private func choiceRow(question: Question, choice: QuestionChoice, index: Int) -> some View {
        let isCorrect = choice.id == question.answer
        let isPicked = choice.id == selectedChoiceID
        let tint: Color = submitted ? (isCorrect ? Palette.success : (isPicked ? Palette.danger : Palette.textTertiary)) : (isPicked ? Palette.accent : Palette.textTertiary)

        return Button {
            guard !submitted else { return }
            selectedChoiceID = choice.id
        } label: {
            HStack(spacing: 12) {
                Text(letter(index))
                    .font(AppFont.caption.bold())
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.14))
                    .clipShape(Circle())
                Text(choice.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                if submitted && (isCorrect || isPicked) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(tint)
                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, Metric.fieldPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isPicked || (submitted && isCorrect) ? tint.opacity(0.10) : Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous)
                    .stroke(isPicked || (submitted && isCorrect) ? tint : Palette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func explanationBlock(_ question: Question) -> some View {
        let correct = selectedChoiceID == question.answer
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: correct ? "checkmark.seal.fill" : "lightbulb.fill")
                    .foregroundStyle(correct ? Palette.success : Palette.warning)
                Text(correct ? "答对了" : "再看一眼思路")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.textPrimary)
            }
            Text(question.explanation)
                .font(AppFont.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((correct ? Palette.success : Palette.warning).opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusTile, style: .continuous))
    }

    private var chunkSummary: some View {
        VStack(spacing: 14) {
            Image(systemName: isLastChunk ? "flag.checkered" : "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(isLastChunk ? Palette.accent : Palette.success)
            Text(isLastChunk ? "本知识点练习完成" : "第 \(chunkIndex + 1) 批完成")
                .font(AppFont.sectionTitle)
                .foregroundStyle(Palette.textPrimary)
            Text("本批答对 \(correctCount) / \(answeredCount) 题")
                .font(AppFont.body)
                .foregroundStyle(Palette.textSecondary)
            if !isLastChunk {
                Text("还有 \(chunkCount - chunkIndex - 1) 批（约 \((chunkCount - chunkIndex - 1) * (chunkSize ?? 5)) 题）在等你。")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            if purchase.hasLockedQuestions(in: lesson) {
                VStack(spacing: 8) {
                    Text("这个知识点还有 \(lesson.questions.count - MathPurchaseManager.freeQuestionsPerLesson) 道完整题组未解锁")
                        .font(AppFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "解锁完整版", icon: "lock.open.fill", tint: Palette.accent, enabled: true) {
                        showPaywall = true
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metric.heroGap)
        .padding(.horizontal, Metric.cardPadding)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metric.radiusCard, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    // MARK: 底部按钮

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if question != nil, !submitted {
                Text(selectedChoiceID == nil ? "先观察，再选出你的答案" : "确认后可以看到解析")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            PrimaryButton(
                title: primaryTitle,
                icon: primaryIcon,
                tint: primaryTint,
                enabled: selectedChoiceID != nil || question == nil
            ) {
                advance()
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, Metric.stack)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var primaryTitle: String {
        guard question != nil else { return isLastChunk ? "收下能力" : "进入下一批" }
        if !submitted { return "确认答案" }
        return step + 1 >= questions.count ? "查看本批结果" : "下一题"
    }

    private var primaryIcon: String {
        guard question != nil else { return isLastChunk ? "checkmark" : "arrow.right" }
        return submitted ? "arrow.right" : "checkmark"
    }

    private var primaryTint: Color { Palette.action }

    // MARK: 流程

    private func advance() {
        PerfProbe.mark()
        guard let question else {
            if isLastChunk {
                finish()
                onComplete()
                dismiss()
            } else {
                chunkIndex += 1
                step = 0
                selectedChoiceID = nil
                submitted = false
                answeredCount = 0
                correctCount = 0
            }
            return
        }

        if !submitted {
            let correct = selectedChoiceID == question.answer
            // 静默写入：做题过程不触发四个 Tab 整棵重算，离开本页时统一刷新一次。
            let t0 = CFAbsoluteTimeGetCurrent()
            store.recordAttempt(questionID: question.id, lessonID: lesson.id, correct: correct, notify: false)
            PerfProbe.log(String(format: "recordAttempt %.2f ms", (CFAbsoluteTimeGetCurrent() - t0) * 1000))
            answeredCount += 1
            if correct { correctCount += 1 }
            withAnimation(.easeInOut(duration: 0.18)) { submitted = true }
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedChoiceID = nil
                submitted = false
                step += 1
            }
        }
    }

    private func finish() {
        if let session, let activity {
            store.completeActivity(activity, in: session, score: accuracy)
        }
    }

    private func letter(_ index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters.indices.contains(index) ? letters[index] : "\(index + 1)"
    }
}

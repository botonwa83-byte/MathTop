import SwiftUI

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
    let onComplete: () -> Void

    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    @State private var chunkIndex = 0
    @State private var step = 0
    @State private var selectedChoiceID: String?
    @State private var submitted = false
    @State private var answeredCount = 0
    @State private var correctCount = 0

    private var chunkCount: Int {
        guard let chunkSize, chunkSize > 0, !lesson.questions.isEmpty else { return 1 }
        return max(1, Int(ceil(Double(lesson.questions.count) / Double(chunkSize))))
    }

    private var questions: [Question] {
        guard let chunkSize, chunkSize > 0 else { return lesson.questions }
        return Array(lesson.questions.dropFirst(chunkIndex * chunkSize).prefix(chunkSize))
    }

    private var question: Question? { questions.indices.contains(step) ? questions[step] : nil }
    private var isLastChunk: Bool { chunkIndex >= chunkCount - 1 }
    private var isLastStep: Bool { step >= questions.count }
    private var accuracy: Double { answeredCount == 0 ? 1 : Double(correctCount) / Double(answeredCount) }

    var body: some View {
        NavigationStack {
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
                    .padding(.bottom, 24)
                }
                bottomBar
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }.foregroundStyle(Palette.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(lesson.title).font(AppFont.cardTitle).foregroundStyle(Palette.textPrimary)
                }
            }
        }
    }

    // MARK: 头部

    private var header: some View {
        HStack(spacing: 8) {
            TagBadge(text: lesson.ability, tint: lesson.stage.tint)
            TagBadge(text: "共 \(lesson.questions.count) 题", tint: Palette.textSecondary)
            if chunkCount > 1 {
                TagBadge(text: "第 \(chunkIndex + 1)/\(chunkCount) 批", tint: Palette.info, icon: "square.stack.3d.up")
            }
            Spacer()
            Text("\(min(step + 1, questions.count)) / \(questions.count)")
                .font(AppFont.caption.bold())
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 8)
    }

    private var progressBar: some View {
        ProgressView(value: Double(min(step, questions.count)), total: Double(max(questions.count, 1)))
            .tint(Palette.accent)
            .padding(.horizontal, Metric.gutter)
            .padding(.top, 10)
    }

    // MARK: 题目

    @ViewBuilder
    private func questionBlock(_ question: Question) -> some View {
        Text(question.prompt)
            .font(AppFont.question)
            .foregroundStyle(Palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 18)
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
            .padding(.horizontal, 14)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
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
        .padding(.top, 12)
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
            store.recordAttempt(questionID: question.id, lessonID: lesson.id, correct: correct)
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

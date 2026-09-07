# MathTop 内容丰富化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前 MathTop 原型升级为面向小学与初中的“能力型学习”App，形成可持续学习、可量化反馈、数学英语双学科联动的内容产品。

**Architecture:** 保留 SwiftUI + XcodeGen + iOS 16 架构，将当前单文件拆成 Models、Store、Features 和 Components。内容由本地 JSON/Swift fixtures 驱动，学习记录由 ObservableObject + UserDefaults 持久化；后续可无痛替换为远端 API。训练统一抽象为 Skill、Lesson、Question、Attempt，数学和英语仅提供不同题型渲染器。

**Tech Stack:** Swift 5, SwiftUI, XcodeGen, XCTest, UserDefaults/JSONDecoder。

**Spec:** 当前对话中的 MathTop 产品方向：小学/初中分层、数学与英语双主线、每日 10 分钟能力训练、能力地图、知识本、错题变身器。

## Global Constraints

- 最低支持 iOS 16.0，继续使用 SwiftUI，不引入第三方依赖。
- 所有学习内容必须标注学科与学段：`math/english`、`primary/junior`。
- 每个训练单元控制在 3-10 分钟，完成后必须产生可见反馈。
- UI 文案面向 7-15 岁学生，避免“失败/笨”等负向措辞。
- 所有数据访问通过 `LearningStore`，视图不得直接读写 UserDefaults。
- 每个任务结束运行对应 XCTest；每个阶段结束运行完整 `xcodebuild`。

### Task 1: 建立领域模型与学习状态层

**Files:**
- Create: `MathTop/Models/LearningModels.swift`
- Create: `MathTop/Store/LearningStore.swift`
- Modify: `MathTop/App/MathTopApp.swift`
- Test: `MathTopTests/LearningStoreTests.swift`

**Interfaces:** `Skill`, `Lesson`, `Question`, `QuestionChoice`, `Attempt`, `Stage`, `Subject`; `LearningStore.completedLessonIDs`, `markLessonCompleted(_:)`, `progress(for:)`。

- [ ] Step 1: 写测试，验证学段/学科编码、完成记录持久化、能力进度计算。
- [ ] Step 2: 运行 `xcodebuild test -project MathTop.xcodeproj -scheme MathTop -destination 'platform=iOS Simulator,name=iPhone 17'`，确认测试先失败。
- [ ] Step 3: 实现 Codable 模型与注入 `@StateObject private var store = LearningStore()`。
- [ ] Step 4: 重新运行同一测试命令，确认通过。
- [ ] Step 5: 提交 `feat: add learning domain and persistence layer`。

### Task 2: 丰富小学/初中数学内容

**Files:**
- Create: `MathTop/Content/MathContent.swift`
- Create: `MathTop/Features/Practice/QuestionRenderer.swift`
- Modify: `MathTop/Features/Practice/PracticeView.swift`
- Test: `MathTopTests/MathContentTests.swift`

**Interfaces:** `MathContent.lessons(for:) -> [Lesson]`; `QuestionRenderer` 根据 `Question.kind` 渲染选择题、填空题、拖拽排序题。

- [ ] Step 1: 写测试，覆盖小学数感/分数/几何、初中方程/函数/概率各至少一个单元，并验证答案解析存在。
- [ ] Step 2: 运行测试确认缺少内容时失败。
- [ ] Step 3: 添加 12 个数学 Lesson（小学 6、初中 6），每个含 3-5 道题、提示和一句“能力解释”。
- [ ] Step 4: 将 `PracticeView` 改为读取 Lesson，完成后调用 `store.markLessonCompleted`。
- [ ] Step 5: 测试并提交 `feat: add primary and junior math curriculum`。

### Task 3: 丰富小学/初中英语内容

**Files:**
- Create: `MathTop/Content/EnglishContent.swift`
- Create: `MathTop/Features/English/WordSprintView.swift`
- Create: `MathTop/Features/English/SentenceLabView.swift`
- Modify: `MathTop/Features/Home/HomeView.swift`
- Test: `MathTopTests/EnglishContentTests.swift`

**Interfaces:** `EnglishContent.lessons(for:)`; 题型包括词义配对、句型重排、听辨占位（先用文本 transcript，预留音频 URL）。

- [ ] Step 1: 写测试，验证小学高频词/初中核心句型内容数量、答案唯一性与学段过滤。
- [ ] Step 2: 运行测试确认失败。
- [ ] Step 3: 添加 12 个英语 Lesson（小学 6、初中 6），覆盖词汇、时态、介词、阅读策略。
- [ ] Step 4: 实现 `WordSprintView` 与 `SentenceLabView`，接入今日任务和能力地图。
- [ ] Step 5: 测试并提交 `feat: add primary and junior english curriculum`。

### Task 4: 能力地图与自适应每日任务

**Files:**
- Create: `MathTop/Features/Path/SkillPathView.swift`
- Create: `MathTop/Services/DailyPlanService.swift`
- Modify: `MathTop/Features/Home/HomeView.swift`
- Modify: `MathTop/Features/Path/PathView.swift`
- Test: `MathTopTests/DailyPlanServiceTests.swift`

**Interfaces:** `DailyPlanService.makePlan(stage:date:store:) -> DailyPlan`; `SkillPathView` 展示锁定、进行中、已掌握三种节点状态。

- [ ] Step 1: 写测试，验证未完成优先、连续学习奖励、数学英语交替推荐。
- [ ] Step 2: 运行测试确认失败。
- [ ] Step 3: 实现基于掌握度与最近学习时间的本地推荐算法。
- [ ] Step 4: 将首页 HeroCard 改为真实每日计划，支持切换小学/初中重新计算。
- [ ] Step 5: 测试并提交 `feat: add adaptive daily learning plan`。

### Task 5: 错题变身器与复习循环

**Files:**
- Create: `MathTop/Features/Review/ErrorBookView.swift`
- Create: `MathTop/Services/ReviewScheduler.swift`
- Modify: `MathTop/Store/LearningStore.swift`
- Test: `MathTopTests/ReviewSchedulerTests.swift`

**Interfaces:** `LearningStore.recordAttempt(_:)`; `ReviewScheduler.nextReviewDate(for:now:)` 使用 1/3/7 天间隔；错误记录包含错误原因标签。

- [ ] Step 1: 写测试，验证答错入错题本、重做正确后延后复习、按学科筛选。
- [ ] Step 2: 运行测试确认失败。
- [ ] Step 3: 实现 Attempt 记录和间隔复习调度。
- [ ] Step 4: 提供“再试一次/看提示/掌握了”三个动作并更新进度。
- [ ] Step 5: 测试并提交 `feat: add error book and spaced review`。

### Task 6: 成长反馈、家长摘要与产品质量

**Files:**
- Create: `MathTop/Features/Profile/GrowthView.swift`
- Create: `MathTop/Features/Parent/WeeklySummaryView.swift`
- Create: `MathTop/Services/GrowthSummaryService.swift`
- Modify: `MathTop/Features/Profile/ProfileView.swift`
- Create: `MathTopUITests/MathTopFlowUITests.swift`

**Interfaces:** `GrowthSummaryService.summary(store:period:) -> GrowthSummary`，输出学习时长、完成单元、掌握能力、建议下一步；家长摘要只读本地聚合数据。

- [ ] Step 1: 写服务测试，验证空数据、连续 7 天、数学英语混合数据三种摘要。
- [ ] Step 2: 实现成长趋势图、徽章和每周摘要，不加入社交排行。
- [ ] Step 3: 增加 UI 测试：启动 → 切换学段 → 开始训练 → 完成 → 首页显示已解锁。
- [ ] Step 4: 运行完整测试与 `xcodebuild build`，修复无障碍标签、深色模式和 Dynamic Type 问题。
- [ ] Step 5: 提交 `feat: add growth feedback and parent summary`。

## Release Checkpoints

- Milestone 1（Task 1-2）：数学内容可选、可练、可记录。
- Milestone 2（Task 3-4）：数学英语双学科每日计划可持续运行。
- Milestone 3（Task 5-6）：错题复习和成长反馈闭环，具备 TestFlight 原型条件。

## Self-Review

- 所有需求均映射到 Task 1-6；没有依赖远端服务或第三方库。
- 计划中没有 TBD/TODO/占位步骤；音频仅作为明确的后续接口预留，不影响本地版本。
- `LearningStore`、`DailyPlanService`、`ReviewScheduler`、`GrowthSummaryService` 的接口在任务间保持一致。

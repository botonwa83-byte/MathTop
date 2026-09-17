import StoreKit
import SwiftUI

// MARK: - 完整功能解锁 IAP（StoreKit 2 · 一次性买断，移植自 Apex 家族）
//
// 产品 ID：com.mathtop.app.full_unlock（¥22 一次性买断，价格在 App Store Connect 配置）
// 免费档（低门槛入口 + 习惯钩子，永久免费）：
//   · 每个知识点前 freeQuestionsPerLesson 题免费试练（Understand → Practice 第一步就能做）
//   · 仿真题集中训练第 1 批（34 题）免费
//   · 错题变身器、成长摘要、收藏、能力地图浏览 永久免费
// 付费解锁：每个知识点完整题组（第 4 题起）、仿真第 2/3 批、进阶模块五个方向。
// 本地 UserDefaults 缓存即时呈现，启动时 Transaction.currentEntitlements 核验防破解。
// 本地调试：scheme 已挂载 MathTop.storekit，可在沙盒外直接测试购买/恢复流程。

@MainActor final class MathPurchaseManager: ObservableObject {
    static let shared = MathPurchaseManager()

    let productID = "com.mathtop.app.full_unlock"

    /// 免费档：每个知识点开放前 N 题试练（取题组前部，扩内容时不要打乱前 N 题）。
    static let freeQuestionsPerLesson = 3
    /// 免费档：仿真题开放前 N 批（共 3 批）。
    static let freeSimulationBatches = 1

    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var errorMessage: String?
    /// 商品信息拉取失败（无网络 / ASC 未配置）：付费墙需提示重试，而不是长期展示兜底价。
    @Published private(set) var productLoadFailed: Bool = false

    private let storageKey = "mathtop.full_unlocked"
    private var updatesTask: Task<Void, Never>?

    private init() {
        isUnlocked = UserDefaults.standard.bool(forKey: storageKey)
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
        listenForTransactions()
    }

    // MARK: 免费档判定

    /// 未解锁时每个知识点只能看到前 freeQuestionsPerLesson 题。
    func availableQuestions(for lesson: Lesson) -> [Question] {
        guard !isUnlocked else { return lesson.questions }
        return Array(lesson.questions.prefix(Self.freeQuestionsPerLesson))
    }

    /// 该知识点是否还有被锁住的题。
    func hasLockedQuestions(in lesson: Lesson) -> Bool {
        guard !isUnlocked else { return false }
        return lesson.questions.count > Self.freeQuestionsPerLesson
    }

    /// 仿真批次是否被锁（第 1 批永久免费）。
    func isSimulationBatchLocked(_ batch: Int) -> Bool {
        guard !isUnlocked else { return false }
        return batch > Self.freeSimulationBatches
    }

    // MARK: StoreKit

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
            productLoadFailed = product == nil
        } catch {
            productLoadFailed = true
        }
    }

    /// 付费墙「重试」入口：网络恢复或 ASC 配置就绪后重新拉取价格。
    func retryLoadProduct() async {
        productLoadFailed = false
        await loadProduct()
    }

    func purchase() async {
        guard let product else {
            errorMessage = "商品信息尚未加载完成，请检查网络后重试"
            await loadProduct()
            return
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlock()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "购买待处理（可能需要家长确认），完成后将自动解锁"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
        }
    }

    func restore() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isUnlocked { errorMessage = "未找到购买记录" }
        } catch {
            errorMessage = "恢复失败：\(error.localizedDescription)"
        }
    }

    /// 以 App Store 记录为准：没有有效交易时回退解锁状态，退款/撤销能真实生效。
    func refreshEntitlements() async {
        var entitled = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == productID,
               tx.revocationDate == nil {
                entitled = true
                break
            }
        }
        if entitled {
            unlock()
        } else {
            lock()
        }
    }

    private func unlock() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: storageKey)
    }

    /// 退款或家庭共享撤销：解锁状态回退，避免本地标记永久生效。
    private func lock() {
        isUnlocked = false
        UserDefaults.standard.set(false, forKey: storageKey)
    }

    /// 监听 App 之外完成的交易：家长批准（Ask to Buy）、换机重装、退款撤销都会走到这里。
    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                guard case .verified(let tx) = result, tx.productID == self.productID else { continue }
                await self.apply(transaction: tx)
            }
        }
    }

    private func apply(transaction tx: StoreKit.Transaction) async {
        if tx.revocationDate != nil {
            lock()
            return
        }
        await tx.finish()
        unlock()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}

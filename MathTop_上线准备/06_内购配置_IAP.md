# MathTop 内购配置（App Store Connect）

## 商品参数

| 项 | 值 |
|----|----|
| 类型 | 非消耗型 / Non-Consumable |
| 产品 ID | `com.mathtop.app.full_unlock` |
| 参考名称（Reference Name） | `MathTop Full Unlock` |
| 显示名称（中文） | `完整版解锁` |
| 价格 | ¥22 档位（以 ASC 实际价格档为准） |
| 家庭共享 | 关闭 |
| 审核截图 | 付费墙截图（建议 6.9" 一张） |

## 商品描述（ASC）

完整版解锁：开放 88 个知识点的完整题组（每个知识点 10 道）、仿真题全三批（100 道）与进阶模块五个方向（竞赛压轴、几何实验室、应用题冲刺、复盘、阶段测评）。免费部分（每知识点前 3 题试练、仿真第 1 批、错题变身器、成长摘要、收藏、能力地图）继续保持免费。无订阅、无续费，支持换机恢复购买。

## 代码一致性核对

| 位置 | 值 | 状态 |
|------|----|------|
| `MathTop/Store/MathPurchaseManager.swift` → `productID` | `com.mathtop.app.full_unlock` | ✅ |
| `MathTop.storekit` → `productID` | `com.mathtop.app.full_unlock` | ✅ |
| `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` | `com.mathtop.app` | ✅ |
| 产品 ID 前缀与 bundle id 一致 | `com.mathtop.app.` | ✅ |

## 免费档划线（代码中的常量）

- `MathPurchaseManager.freeQuestionsPerLesson = 3`：每个知识点只开放前 3 题。
- `MathPurchaseManager.freeSimulationBatches = 1`：仿真只开放第 1 批。
- 由 `Tests/MathTopTests.swift` 的 `testFreeTierPolicy` / `testFreeSimulationBatchIsUsable` 守门。
- 扩内容时**不要打乱题组前 3 题**。

## 提交前

- ⬜ 在 ASC「App 内购买项目」创建上述商品，状态设为「准备提交」。
- ⬜ 在版本页勾选本商品随版本一起提交。
- ⬜ 沙盒实测：购买解锁、恢复购买、取消不解锁、删除重装可恢复。

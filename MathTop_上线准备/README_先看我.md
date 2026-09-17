# MathTop 上线准备包

生成于 2026-09-17，对应版本 1.0.0(1)，Bundle ID `com.mathtop.app`。

> 隐私政策 / 用户协议 / 技术支持正文统一放在仓库根目录 `docs/`（`docs/index.html`、`docs/privacy.html`、`docs/terms.html`、`docs/support.html`）。

## 文件导览

| 文件 | 用途 |
|------|------|
| `00_上线总检查清单.md` | 从这里开始：阻断项、后台待办、已验证项 |
| `01_App Store商品信息.md` | 名称、副标题、关键词、描述、更新说明，可直接复制 |
| `04_App隐私问卷答案.md` | App Privacy 问卷答案，结论：不收集数据 |
| `05_审核备注_ReviewNotes.md` | 审核备注，中英双语，含内购测试路径 |
| `06_内购配置_IAP.md` | ASC 内购参数，产品 ID 与代码一致性核对 |
| `07_年龄分级问卷.md` | 年龄分级逐项答案，建议 4+ |
| `08_截图与素材清单.md` | 截图尺寸、建议取景、内购截图要求 |
| `09_GitHub_Pages_托管说明.md` | privacy / terms / support 静态页托管说明 |

## 本轮整改已完成的工程项

- **内购体系从 0 到 1**：新增 `MathPurchaseManager`（StoreKit 2）、`MathPaywallView`、`MathTop.storekit`（已挂 scheme）。
- **免费档划线**：每知识点前 3 题 + 仿真第 1 批（34 题）免费；完整题组（每知识点 10 道）、仿真第 2/3 批、进阶模块五方向为付费内容。
- 工程配置：iPad 四向支持、`ITSAppUsesNonExemptEncryption=NO`、单元测试 target 进工程。
- 合规入口：「我的」页与付费墙均接了用户协议 / 隐私政策 / 技术支持链接。
- 隐私清单：`MathTop/Resources/PrivacyInfo.xcprivacy`（声明仅使用 UserDefaults）。
- iPad 可读宽度：主要滚动页已套 `mathReadableWidth()`。
- 图标 alpha 已压平（1024×1024，无透明通道）；删除误拷入的空 `ChinTopApp/` 目录。

## 提交前仍需人工完成

1. ASC 创建内购 `com.mathtop.app.full_unlock`（¥22，随版本提交）。
2. 推送仓库后启用 Pages（`main /docs`），验证三个 URL 可访问。
3. 补齐 iPhone 6.9" 与 iPad 13" 截图。
4. 实机走一遍内购：购买 / 恢复 / 取消 / 删除重装恢复。

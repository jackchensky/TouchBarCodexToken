# PROJECT_STATUS

最后更新：2026-10-07

## 项目概况

TouchBarCodexToken 是一个 Swift/AppKit macOS 菜单栏、桌面 HUD 和 Touch Bar 小工具。应用通过本机 ChatGPT/Codex 包内的 `codex app-server` 调用 `account/rateLimits/read`，显示额度窗口、可用重置次数、额度点数和本地 token 用量。

- 当前分支：`main`
- 当前版本：`0.1.15`，Build `16`（构建和运行验证通过）
- GitHub `main` 版本：`0.1.15`（2026-10-07）
- 最近正式标签：`v0.1.4`

## 已完成

- 兼容 `/Applications/ChatGPT.app` 和旧版 `/Applications/Codex.app` 中的 app-server。
- LaunchAgent 可识别 `ChatGPT`、`Codex` 和 `GPT`，宿主启动时自动拉起额度条。
- 宿主退出时自动关闭额度条；手动退出锁仍然保留。
- 菜单栏、HUD 和 Touch Bar 共用同一份 `RateLimitDisplayState`。
- 刷新失败时保留旧额度数据，本地 token 用量在后台读取。
- 重置时间使用双位 `MM月dd日 HH:mm` 格式。
- HUD 双额度宽度已从 `238px` 调整为 `250px`，单个额度项从 `70px` 调整为 `76px`，避免 `5h 100%` 的百分号被裁切。

## 0.1.15 更新

- 对照当前 ChatGPT 设置和 OpenAI 官方说明，确认推荐奖励属于使用额度，不应标记为美元金额。
- 已直接调用 ChatGPT 内置 `codex-cli 0.158.0-alpha.2.1` 验证 `account/rateLimits/read`：`credits.balance` 仍为数值字符串，响应中没有币种字段。
- Touch Bar 尾部由 `金额：XX.XX刀` 改为 `额度：XX.XX`，只有周额度时的独立第二行也统一为 `额度：XX.XX`。
- 版本更新为 `0.1.15`，Build `16`；Release 构建、本机重启和新版 app-server 进程验证通过，并已提交推送到 `main`。

## 0.1.14 更新

- 诊断确认 ChatGPT `26.924.22138` 将内置 Codex CLI 从 `Contents/Resources/codex` 移至 `Contents/Resources/codex-cli/bin/codex`，旧路径失效导致 app-server 无法启动、额度数据为空。
- app-server 客户端现同时兼容新旧两种相对路径，并通过 `com.openai.codex` / `com.openai.chatgpt` Bundle 标识补充查找宿主 App。
- 已直接调用新版 `codex-cli 0.158.0-alpha.2.1` 验证 `account/rateLimits/read`，5 小时、周额度、重置次数和点数字段结构保持兼容。
- README 已更新新版命令路径与 0.1.14 说明。
- Release 构建已通过；重启后已确认额度条主进程成功拉起新版路径下的 app-server。
- Touch Bar 两行 token 数据右侧新增固定尾部列：第一行显示 `| 重置：N次`，第二行显示 `| 金额：XX.XX刀`；余额为零时也显示 `金额：0.00刀`。
- 新尾部列已完成 Release 构建并重启本地 App；两行分隔线和文字使用固定宽度约束，待实体 Touch Bar 目视确认最终间距。
- 已为 0.1.14 小红书更新帖生成美化后的 Touch Bar 实拍、同系列竖版封面和配套文案，文件位于 `Marketing/xhs-v014-*`，尚未提交或推送。
- 小红书正文已补充获取方式，明确最新源码位置、构建命令、系统兼容性，以及 0.1.14 尚无签名 DMG 的现状。
- 小红书正文已从超长版本压缩为 1000 字限制内的发布版，保留 vibe coding、核心功能、版本变化和获取方式。
- 已完成小红书低流量风险排查：正文移除 GitHub 定向搜索、下载源码、运行脚本、未签名 DMG 和右键绕过提示等高风险站外导流/软件分发表述，并补充 AI 辅助说明。

## 0.1.6 更新

以下改动已经完成构建、本机运行测试并推送到 `main`：

- 严格按照 `windowDurationMins` 区分 5 小时和周额度，不再把唯一的周额度重复映射为 `5h`。
- 解析 `rateLimitResetCredits`，共享状态中增加可用完整重置次数和最早到期日期。
- 有 5 小时窗口时显示 `5h + 7d`。
- 只有周额度且存在重置次数时显示 `重置 x次 + 7d`。
- 没有 5 小时窗口和重置次数时只显示周额度，HUD 自动收窄到 `160px`。
- Touch Bar 第一行可动态切换为“5 小时”或“重置券”。
- Touch Bar Codex 图标改为优先读取 ChatGPT 包内的白底 `icon-codex-light.png`，黑底图标、旧 Codex 图标和 App 图标作为后备。
- Touch Bar 将重置/到期文字、`|` 分隔线、昨日/累计用量拆成固定列，保证上下两行分隔线对齐。
- README 已增加 `0.1.6` 功能说明，并为 `0.1.0` 至 `0.1.6` 的更新记录补齐日期。

涉及文件：

- `README.md`
- `Resources/Info.plist`
- `Sources/AppDelegate.swift`
- `Sources/CompactHUDPanel.swift`
- `Sources/CompactHUDViewController.swift`
- `Sources/LimitModels.swift`
- `Sources/RateLimitStore.swift`
- `Sources/TouchBarRateLimitsView.swift`

## 0.1.7 更新

- HUD 透明度最低支持从 `45%` 放宽到 `10%`。
- 设置菜单新增 `10% / 20% / 30% / 40% / 50%`，并保留原有较高透明度档位。
- 该版本的透明度只影响 HUD 背景，文字、状态点和操作按钮保持完全不透明。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 0.1.8 更新

- HUD 胶囊背景、额度文字、状态点、刷新和退出按钮改为使用统一透明度。
- 修复低透明度下背景与前景视觉不统一的问题。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 0.1.9 更新

- 桌面 HUD 新增原生右键菜单，可直接隐藏浮窗、刷新额度、修改颜色和透明度或退出。
- 右键菜单与菜单栏共用外观设置状态，当前颜色和透明度勾选保持同步。
- 右键隐藏 HUD 后可从菜单栏重新显示。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 0.1.10 更新

- HUD 背景透明度与文字透明度拆分为两个独立设置。
- `背景透明度` 只控制胶囊底色；`文字透明度` 同时控制额度文字、状态点、刷新和退出图标。
- 菜单栏和 HUD 右键菜单共用两组外观状态，当前选项保持同步。
- 旧版统一透明度设置会自动迁移到新的背景和文字透明度，不会丢失用户选择。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 0.1.11 更新

- 解析新版 app-server `RateLimitSnapshot.credits` 中的美元点数余额，并格式化为两位小数。
- 只有周额度时，Touch Bar 使用独立第二行显示 `还剩点数：US$XX.XX`。
- 同时存在 5 小时和周额度时，点数跟随第二行周额度显示，保持最多两行。
- 点数为 0、不可用、无限额度或接口未返回余额时自动隐藏。
- 降低额度行固定高度约束优先级，使隐藏行真正折叠并修复单行内容垂直偏移。
- 已用本机 app-server 实际响应验证点数字段，并完成 Release 构建和本机重启验证后推送到 `main`。

## 0.1.12 更新

- HUD 单个额度区域从 `70px` 加宽到 `76px`，修复 `5h 100%` 和 `7d 100%` 百分号被裁切的问题。
- 双额度 HUD 宽度从 `238px` 调整为 `250px`，单额度 HUD 从 `160px` 调整为 `166px`。
- 胶囊高度、操作按钮尺寸和内部间距保持不变。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 0.1.13 更新

- 修复新版 GPT 接管 Touch Bar 后，点击桌面 HUD 无法重新显示额度条的问题。
- 用户点击 HUD 时显式激活额度条并让面板成为 key window。
- Touch Bar 在创建后重置 first responder，强制 macOS 重新读取额度条。
- 自动启动路径不主动激活应用，继续避免抢占 GPT 输入焦点。
- 已完成 Release 构建和本机重启验证，并推送到 `main`。

## 验证状态

- `git diff --check`：通过。
- `scripts/build-app.sh`：通过，生成 `build/TouchBarCodexToken.app`。
- SwiftPM 会因本机 Command Line Tools 的 `PlatformPath` 探测问题失败，构建脚本会自动使用 `swiftc -sdk` 后备路径并成功完成构建。
- `TouchBarCodexToken` 主进程和 `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex app-server --listen stdio://` 子进程已成功运行。
- 已用当前“只返回周额度”的接口结构验证动态分类逻辑。
- Touch Bar 最终图标、文字间距和分隔线仍应在实体 Touch Bar 上做一次目视确认。

## 未解决和注意事项

- `0.1.14` 尚未创建 Git 标签、DMG 或 GitHub Release。
- 项目目前没有自动化测试，额度接口结构变化主要依赖本机 app-server 和实体 Touch Bar 验证。
- App 尚未使用 Apple Developer 证书签名和公证，公开分发时仍可能出现 macOS 安全提示。
- 以下 Marketing 文件是未跟踪草稿，除非明确要求，否则不要加入提交：
  - `Marketing/promo-style-a-touchbar-soul.png`
  - `Marketing/promo-style-b-warm-fresh.png`
  - `Marketing/promo-style-c-editorial-clean.png`
  - `Marketing/promo-style-d-tech-board-v2.png`
  - `Marketing/xhs-v014-cover-update.png`
  - `Marketing/xhs-v014-post-copy.md`
  - `Marketing/xhs-v014-touchbar-photo-enhanced.png`

## 建议下一步

1. 在实体 Touch Bar 上继续观察白底 Codex 图标、重置券行和两行 `|` 分隔线在不同额度值下的对齐情况。
2. 按需要为 `0.1.15` 创建 Git 标签、DMG 和 GitHub Release。
3. 后续 app-server 返回结构变化时，优先检查额度窗口时长和重置券字段。

## 常用命令

```bash
scripts/build-app.sh
scripts/package-dmg.sh
open build/TouchBarCodexToken.app
git status --short --branch
```

# PROJECT_STATUS

最后更新：2026-07-18

## 项目概况

TouchBarCodexToken 是一个 Swift/AppKit macOS 菜单栏、桌面 HUD 和 Touch Bar 小工具。应用通过本机 ChatGPT/Codex 包内的 `codex app-server` 调用 `account/rateLimits/read`，显示额度窗口、可用重置次数和本地 token 用量。

- 当前分支：`main`
- 当前版本：`0.1.6`，Build `7`
- GitHub `main` 版本：`0.1.6`（2026-07-18）
- 最近正式标签：`v0.1.4`

## 已完成

- 兼容 `/Applications/ChatGPT.app` 和旧版 `/Applications/Codex.app` 中的 app-server。
- LaunchAgent 可识别 `ChatGPT`、`Codex` 和 `GPT`，宿主启动时自动拉起额度条。
- 宿主退出时自动关闭额度条；手动退出锁仍然保留。
- 菜单栏、HUD 和 Touch Bar 共用同一份 `RateLimitDisplayState`。
- 刷新失败时保留旧额度数据，本地 token 用量在后台读取。
- 重置时间使用双位 `MM月dd日 HH:mm` 格式。
- HUD 已从 `226px` 加宽到 `238px`，避免两个 `100%` 同时显示时百分号被遮挡。

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

## 验证状态

- `git diff --check`：通过。
- `scripts/build-app.sh`：通过，生成 `build/TouchBarCodexToken.app`。
- SwiftPM 会因本机 Command Line Tools 的 `PlatformPath` 探测问题失败，构建脚本会自动使用 `swiftc -sdk` 后备路径并成功完成构建。
- `TouchBarCodexToken` 主进程和 `/Applications/ChatGPT.app/Contents/Resources/codex app-server --listen stdio://` 子进程已成功运行。
- 已用当前“只返回周额度”的接口结构验证动态分类逻辑。
- Touch Bar 最终图标、文字间距和分隔线仍应在实体 Touch Bar 上做一次目视确认。

## 未解决和注意事项

- `0.1.6` 尚未创建 Git 标签、DMG 或 GitHub Release。
- 项目目前没有自动化测试，额度接口结构变化主要依赖本机 app-server 和实体 Touch Bar 验证。
- App 尚未使用 Apple Developer 证书签名和公证，公开分发时仍可能出现 macOS 安全提示。
- 以下 Marketing 文件是未跟踪草稿，除非明确要求，否则不要加入提交：
  - `Marketing/promo-style-a-touchbar-soul.png`
  - `Marketing/promo-style-b-warm-fresh.png`
  - `Marketing/promo-style-c-editorial-clean.png`
  - `Marketing/promo-style-d-tech-board-v2.png`

## 建议下一步

1. 在实体 Touch Bar 上继续观察白底 Codex 图标、重置券行和两行 `|` 分隔线在不同额度值下的对齐情况。
2. 按需要创建 `v0.1.6` 标签、DMG 和 GitHub Release。
3. 后续 app-server 返回结构变化时，优先检查额度窗口时长和重置券字段。

## 常用命令

```bash
scripts/build-app.sh
scripts/package-dmg.sh
open build/TouchBarCodexToken.app
git status --short --branch
```

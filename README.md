# TouchBarCodexToken

TouchBarCodexToken 是一个 macOS 菜单栏 + 桌面 HUD 小工具，用本机 Codex app-server 读取 Codex 额度，并把额度窗口或可用重置次数显示在桌面小浮窗和 Touch Bar 上。

![TouchBarCodexToken 宣传图](Marketing/promo-style-d-tech-board.png)

Touch Bar 清晰细节：

![Touch Bar 清晰细节](Marketing/promo-touchbar-upgrade-detail.png)

它不抓网页，也不需要你填写 API Key。应用会自动查找 ChatGPT 合并版或旧版 Codex 中的本机 `codex`：

```bash
/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex app-server --listen stdio://
# 或旧版
/Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
```

然后通过 JSON-RPC 调用：

```text
account/rateLimits/read
```

## 作者

- 个人博客：[jackchen.cn](https://jackchen.cn)
- 小红书：Jackchen

## 功能

- 桌面置顶小 HUD：动态显示 `5h xx%`、`7d xx%` 或 `重置 x次`，并提供刷新和退出图标。
- 菜单栏状态：根据接口实际返回显示额度窗口；只有周额度时不再重复显示成 5 小时额度。
- Touch Bar：点击 HUD 后尝试显示两行分段电量条。
- 同步状态：菜单栏、HUD 和 Touch Bar 使用同一份额度状态。
- 自动联动 Codex：检测到 ChatGPT 合并版或旧版 Codex 启动后显示 HUD，宿主应用退出后自动退出。
- 自动拉起：首次运行 app 后会注册本机 LaunchAgent，之后 Codex 启动时自动打开额度条。
- 刷新保护：刷新失败时保留旧数据，不清空已有额度。
- 外观设置：可从菜单栏或 HUD 右键菜单分别修改颜色、背景透明度和文字透明度。
- 本地优先：只调用本机 Codex app-server，不保存账号、密钥或授权码。

## 兼容性

### Mac 机型

| 机型 | 支持情况 | 说明 |
| --- | --- | --- |
| Intel Mac | 支持 | 当前发布的 DMG 是 `x86_64` 构建，适合 Intel 芯片 Mac，包括 2016-2019 款带 Touch Bar 的 MacBook Pro。 |
| Apple Silicon Mac | 支持 | M1 / M2 / M3 / M4 系列 Mac 可通过 Rosetta 2 运行当前 Intel 版应用；首次打开时系统可能提示安装 Rosetta。 |
| 无 Touch Bar 的 Mac | 支持 | 桌面 HUD 和菜单栏额度显示可以正常使用，只是不会显示 Touch Bar 额度条。 |

### Touch Bar

Touch Bar 不是必需硬件。

- 有 Touch Bar 的 Mac：可以使用桌面 HUD、菜单栏和 Touch Bar 额度条。
- 没有 Touch Bar 的 Mac：可以正常使用桌面 HUD 和菜单栏，Touch Bar 相关功能会自然不可见。

### 系统和依赖

- macOS 11 Big Sur 或更新版本。
- 已安装 `/Applications/ChatGPT.app`（Codex 合并版）或旧版 `/Applications/Codex.app`。
- 本机 Codex app-server 可用。

## 界面

HUD 默认是一个小胶囊浮窗，放在屏幕上方附近：

```text
● 5h 85%   ● 7d 80%   ↻   ×
```

如果当前账号只返回周额度，同时拥有可用的完整重置次数，则显示为：

```text
● 重置 3次   ● 7d 96%   ↻   ×
```

如果没有可用重置次数，则只显示周额度并自动收窄浮窗。

- `↻`：刷新额度。
- `×`：退出应用。
- 状态点为绿色、黄色或红色，表示剩余额度充足、偏低或较低。
- 如果读取失败且没有旧数据，状态点会显示红色。
- 鼠标悬停在 HUD 上可以看到当前状态说明。
- 在 HUD 上点击右键，可直接打开隐藏、刷新、颜色、背景透明度、文字透明度和退出菜单。

## Touch Bar

点击桌面 HUD 主体区域时，应用会尝试让 macOS 显示 Touch Bar 额度条。

Touch Bar 内容包括：

- Codex 官方图标。
- `5 小时` 额度分段电量条；窗口不存在时改为显示可用重置次数和最早到期日期。
- `周限额` 分段电量条。
- 剩余百分比。
- 重置时间。
- 本地 token 消耗统计：`昨日` 和 `累计`。
- 只有周额度时，第二行单独显示使用额度，例如 `额度：147.56`；两种额度窗口都存在时，额度跟随第二行周额度显示。余额为 0 时显示 `额度：0.00`，只有接口未返回额度时才隐藏。

注意：macOS 的公开 Touch Bar API 与当前前台 App / first responder 绑定。切回 Codex 输入后，Touch Bar 可能会被 Codex 自己接管，这是系统限制。

## 菜单栏和 HUD 右键菜单

点击菜单栏图标，或在桌面 HUD 上点击右键，可以打开原生 macOS 菜单：

- `显示浮窗` / `隐藏浮窗`
- `刷新额度`
- `设置`
  - `浮窗颜色`
    - 深黑
    - 石墨
    - 深蓝
    - 深绿
    - 紫色
  - `背景透明度`
    - 10%
    - 20%
    - 30%
    - 40%
    - 50%
    - 60%
    - 75%
    - 86%
    - 100%
  - `文字透明度`
    - 10%
    - 20%
    - 30%
    - 40%
    - 50%
    - 60%
    - 75%
    - 86%
    - 100%
- `退出`

HUD 右键菜单只显示 `隐藏浮窗`；隐藏后可以从菜单栏重新显示。两处菜单使用同一份颜色和两项透明度状态，选中项会同步显示。

背景透明度只控制胶囊底色；文字透明度同时控制额度文字、状态点、刷新和退出图标。设置会保存到 `UserDefaults`，下次启动继续生效。

## 安装和运行

### 方式一：构建 app

```bash
scripts/build-app.sh
```

构建成功后会生成：

```text
build/TouchBarCodexToken.app
```

双击这个 app，或运行：

```bash
open build/TouchBarCodexToken.app
```

首次运行后，应用会在当前用户的 `~/Library/LaunchAgents` 下注册一个轻量启动器：

```text
com.jackchen.TouchBarCodexToken.CodexLauncher.plist
```

它每 5 秒检查一次 ChatGPT 合并版或旧版 Codex 是否正在运行。如果宿主应用已启动而额度条未运行，就自动打开 `TouchBarCodexToken.app`。如果你在宿主应用仍运行时手动退出额度条，本轮会话内不会被自动拉起；宿主应用完全退出后会清除这个手动退出状态。

### 方式二：打包 DMG

```bash
scripts/package-dmg.sh
```

打包成功后会生成：

```text
dist/TouchBarCodexToken-0.1.6.dmg
```

分享给其他人时，推荐上传这个 DMG 到 GitHub Releases。当前项目没有 Apple Developer 签名和公证，首次打开时 macOS 可能提示无法验证开发者；用户可以在 Finder 中右键点击 app，选择“打开”，再确认一次。

### 方式三：开发期直接运行

```bash
swift run
```

## 要求

见上方“兼容性”章节。

## 构建说明

项目使用 Swift / AppKit 实现。

常规构建走 SwiftPM：

```bash
swift build -c release
```

如果本机 Command Line Tools 的 SwiftPM SDK 探测失败，`scripts/build-app.sh` 会 fallback 到 `swiftc -sdk` 直接编译。

### 重新生成 App 图标

项目图标源图在 `Resources/AppIcon.png`，macOS 图标文件在 `Resources/AppIcon.icns`。

```bash
scripts/make-app-icon.py
```

脚本会为 Finder 列表视图常用的小尺寸层生成专门的简化图标，并用标准 ICNS 写入器输出，避免小图标被直接缩小或被系统读成杂色噪点。

## 更新记录

### 0.1.15 - 2026-10-07

- 适配 ChatGPT/Codex 将推荐奖励明确为“使用额度”的新语义。
- Touch Bar 尾部由 `金额：XX.XX刀` 改为 `额度：XX.XX`，不再把 `credits.balance` 错标为美元金额。
- 只有周额度时，独立第二行由 `还剩点数：US$XX.XX` 改为 `额度：XX.XX`。
- 已使用当前 ChatGPT 内置 app-server 的真实响应验证：接口仍返回 `credits.balance` 数值，但没有货币单位字段。
- 应用版本更新为 `0.1.15`，Build `16`。

### 0.1.14 - 2026-09-28

- 适配新版 ChatGPT `26.924.22138` 调整后的内置 Codex CLI 路径：`Contents/Resources/codex-cli/bin/codex`。
- 同时保留旧版 `Contents/Resources/codex` 路径兼容，不影响尚未升级的 ChatGPT/Codex。
- 增加按 App Bundle 标识查找 ChatGPT 的后备方式，应用不在标准名称或位置时也可尝试定位 app-server。
- 已确认新版 app-server 的 `account/rateLimits/read` 协议和额度字段仍兼容，数据消失并非额度接口下线。
- Touch Bar 在昨日 token 数据右侧增加 `| 重置：N次`，数据缺失时显示占位，已读取但无重置次数时显示 `重置：0次`。
- Touch Bar 在累计 token 数据右侧增加 `| 金额：XX.XX刀`，余额为零时固定显示 `金额：0.00刀`。
- 两行新增独立分隔线与固定宽度尾部列，保证 `|`、`重置` 和 `金额` 在数值变化时仍上下对齐。
- 应用版本更新为 `0.1.14`，Build `15`，已完成 Release 构建、重启和新版 app-server 进程验证。

### 0.1.13 - 2026-08-27

- 修复新版 GPT 接管 Touch Bar 后，点击桌面 HUD 无法重新显示额度条的问题。
- 用户点击 HUD 时会显式激活额度条、让浮窗成为 key window，并重新创建 Touch Bar 与 first responder 链。
- 自动启动时仍保持后台运行，不主动抢占 GPT 的键盘输入焦点。

### 0.1.12 - 2026-08-26

- HUD 单个额度区域从 `70px` 加宽到 `76px`，修复 `5h 100%` 和 `7d 100%` 百分号被裁切的问题。
- 双额度 HUD 宽度从 `238px` 调整为 `250px`，单额度 HUD 从 `160px` 调整为 `166px`。
- 保持胶囊高度、操作按钮尺寸和内部间距不变，只增加完整显示最长百分比所需的宽度。

### 0.1.11 - 2026-08-20

- 适配新版 Codex `account/rateLimits/read` 返回的 `credits.balance`，Touch Bar 可显示 `还剩点数：US$XX.XX`。
- 只有周额度时，周额度显示在第一行，剩余点数独立显示在第二行；同时存在 5 小时和周额度时，点数跟随第二行周额度显示。
- 点数为 0、不可用、无限额度或接口未返回余额时自动隐藏，不占用 Touch Bar 空间。
- 修复隐藏的额度行仍占据高度、导致文字和胶囊条相对 Codex 图标整体偏上的问题。

### 0.1.10 - 2026-08-01

- HUD 背景透明度与文字透明度拆分为两个独立设置。
- `背景透明度` 只控制胶囊底色；`文字透明度` 同时控制额度文字、状态点、刷新和退出图标。
- 菜单栏和 HUD 右键菜单同步两组选中状态，并自动迁移旧版统一透明度设置。

### 0.1.9 - 2026-07-31

- 桌面 HUD 新增原生右键菜单，可直接隐藏浮窗、刷新额度、修改颜色和透明度或退出。
- HUD 右键菜单与菜单栏共用同一份外观状态，颜色和透明度勾选会保持同步。
- 右键隐藏 HUD 后，可从菜单栏的 `显示浮窗` 恢复。

### 0.1.8 - 2026-07-30

- HUD 胶囊背景、额度文字、状态点、刷新和退出按钮改为使用统一透明度。
- 修复低透明度下背景已经变淡、前景内容仍保持完全不透明而显得不协调的问题。

### 0.1.7 - 2026-07-29

- HUD 透明度最低支持从 `45%` 放宽到 `10%`。
- 透明度菜单新增 `10% / 20% / 30% / 40% / 50%` 连续档位，并保留原有 `60% / 75% / 86% / 100%`。
- 透明度只影响 HUD 胶囊背景，额度文字、状态点、刷新和退出按钮保持清晰。

### 0.1.6 - 2026-07-18

- 适配只返回周额度的新账号结构，不再把同一份周额度重复显示成 `5h`。
- 没有 5 小时窗口时，HUD、菜单栏和 Touch Bar 动态显示可用完整重置次数。
- 没有可用重置次数时只显示周额度，并自动收窄 HUD。
- 修复 Codex 合并到 ChatGPT 后 Touch Bar 左侧官方图标不显示的问题，优先使用白底 Codex 官方图标。
- Touch Bar 的到期/重置文字、`|` 分隔线和昨日/累计用量改为固定列，上下两行保持对齐。
- HUD 小幅加宽，避免 `5h 100%` 与 `7d 100%` 同时显示时百分号被遮挡。

### 0.1.5 - 2026-07-10

- 兼容 Codex 合并到 ChatGPT 后的新应用名称和安装路径。
- 自动启动器现在可识别 `ChatGPT`、`Codex` 和 `GPT` 进程。
- app-server 会自动从 ChatGPT 合并版或旧版 Codex 中选择可用的本机 `codex`。
- 应用内生命周期监听同步兼容新旧宿主，继续保持宿主启动时拉起、退出时关闭。

### 0.1.4 - 2026-06-16

- README 增加 Intel Mac、Apple Silicon Mac、无 Touch Bar Mac 的兼容性说明。
- Touch Bar 增加本地 token 消耗统计，显示 `昨日` 和 `累计` 用量。
- 重置时间统一显示为 `MM月dd日 HH:mm 重置`，让 5 小时额度和周额度两行更容易对齐阅读。
- 本地 token 统计改为后台读取，避免刷新时桌面 HUD 和菜单栏短暂卡住。
- 更新 README 宣传图，并新增一张更清晰的 Touch Bar 细节图。

### 0.1.3 - 2026-06-13

- 新增 LaunchAgent 启动器，首次运行后可在 Codex 启动时自动打开额度条。
- 新增 `scripts/package-dmg.sh`，可生成用于分享安装的 DMG。
- README 加入第一版项目宣传图。

### 0.1.2 - 2026-06-11

- 修正 Finder 详情列表小图标模式下图标显示成彩色噪点的问题。
- 调整 `scripts/make-app-icon.py`，改用 Pillow 的标准 ICNS 写入器生成兼容的小尺寸图层。

### 0.1.1 - 2026-06-11

- 修正 Finder 列表等小尺寸场景下 App 图标显示不清楚的问题。
- 新增 `scripts/make-app-icon.py`，用于重新生成带专门小尺寸图层的 `AppIcon.icns`。

### 0.1.0 - 2026-06-10

- 首次开源发布 Swift/AppKit 菜单栏、桌面 HUD 和 Touch Bar 应用。
- 通过本机 Codex app-server 读取 5 小时额度和周额度，不抓网页、不需要 API Key。
- 菜单栏、HUD 和 Touch Bar 使用同一份额度状态，并支持刷新失败时保留旧数据。

## 隐私

TouchBarCodexToken 不保存密码、API Key、授权码或账号凭据。额度数据来自本机 Codex app-server，并只显示在本机 UI 中。

## 许可证

MIT License

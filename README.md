# TouchBarCodexToken

TouchBarCodexToken 是一个 macOS 菜单栏 + 桌面 HUD 小工具，用本机 Codex app-server 读取 Codex 额度，并把 5 小时额度和周额度显示在桌面小浮窗和 Touch Bar 上。

它不抓网页，也不需要你填写 API Key。应用会启动本机：

```bash
/Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
```

然后通过 JSON-RPC 调用：

```text
account/rateLimits/read
```

## 功能

- 桌面置顶小 HUD：显示 `5h xx%`、`7d xx%`、刷新图标和退出图标。
- 菜单栏状态：显示 5 小时额度和周额度的剩余百分比。
- Touch Bar：点击 HUD 后尝试显示两行分段电量条。
- 同步状态：菜单栏、HUD 和 Touch Bar 使用同一份额度状态。
- 自动联动 Codex：检测到 Codex 启动后显示 HUD，Codex 退出后自动退出。
- 刷新保护：刷新失败时保留旧数据，不清空已有额度。
- 外观设置：菜单栏里可修改 HUD 颜色和透明度。
- 本地优先：只调用本机 Codex app-server，不保存账号、密钥或授权码。

## 界面

HUD 默认是一个小胶囊浮窗，放在屏幕上方附近：

```text
● 5h 85%   ● 7d 80%   ↻   ×
```

- `↻`：刷新额度。
- `×`：退出应用。
- 状态点为绿色、黄色或红色，表示剩余额度充足、偏低或较低。
- 如果读取失败且没有旧数据，状态点会显示红色。
- 鼠标悬停在 HUD 上可以看到当前状态说明。

## Touch Bar

点击桌面 HUD 主体区域时，应用会尝试让 macOS 显示 Touch Bar 额度条。

Touch Bar 内容包括：

- Codex 官方图标。
- `5 小时` 额度分段电量条。
- `周限额` 分段电量条。
- 剩余百分比。
- 重置时间。

注意：macOS 的公开 Touch Bar API 与当前前台 App / first responder 绑定。切回 Codex 输入后，Touch Bar 可能会被 Codex 自己接管，这是系统限制。

## 菜单栏

点击菜单栏图标可以打开菜单：

- `显示浮窗` / `隐藏浮窗`
- `刷新额度`
- `设置`
  - `浮窗颜色`
    - 深黑
    - 石墨
    - 深蓝
    - 深绿
    - 紫色
  - `透明度`
    - 60%
    - 75%
    - 86%
    - 100%
- `退出`

设置会保存到 `UserDefaults`，下次启动继续生效。

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

### 方式二：开发期直接运行

```bash
swift run
```

## 要求

- macOS 11 或更新版本。
- 已安装 `/Applications/Codex.app`。
- 本机 Codex app-server 可用。
- 需要 Touch Bar 的 Mac 才能看到 Touch Bar 视图；没有 Touch Bar 的机器仍可使用桌面 HUD 和菜单栏。

## 构建说明

项目使用 Swift / AppKit 实现。

常规构建走 SwiftPM：

```bash
swift build -c release
```

如果本机 Command Line Tools 的 SwiftPM SDK 探测失败，`scripts/build-app.sh` 会 fallback 到 `swiftc -sdk` 直接编译。

## 隐私

TouchBarCodexToken 不保存密码、API Key、授权码或账号凭据。额度数据来自本机 Codex app-server，并只显示在本机 UI 中。

## 许可证

MIT License

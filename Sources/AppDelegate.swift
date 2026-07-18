import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, RateLimitStoreDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 118)
    private let store = RateLimitStore()
    private let lifecycleMonitor = CodexLifecycleMonitor()
    private var hudAppearance = HUDAppearance.load()
    private var hudVisibilityMenuItem: NSMenuItem?
    private var colorMenuItems: [HUDAppearance.ColorChoice: NSMenuItem] = [:]
    private var opacityMenuItems: [Double: NSMenuItem] = [:]
    private lazy var hudController = CompactHUDViewController(
        initialAppearance: hudAppearance,
        onRefresh: { [weak self] in
            self?.refreshQuotaNow()
        },
        onQuit: { [weak self] in
            self?.quitFromHUD()
        }
    )
    private lazy var hudWindow = CompactHUDPanel(contentViewController: hudController)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        store.delegate = self
        configureStatusItem()
        configureLifecycleMonitor()
        CodexAutoLauncher.installOrUpdate()
        CodexAutoLauncher.clearManualQuitLock()

        lifecycleMonitor.start()

        if lifecycleMonitor.codexIsRunningNow() {
            codexDidStart()
        } else {
            updateStatusTitle(with: .initial)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycleMonitor.stop()
        store.stop()
    }

    func rateLimitStore(_ store: RateLimitStore, didUpdate state: RateLimitDisplayState) {
        updateStatusTitle(with: state)
        hudController.update(with: state)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "bolt.horizontal.circle.fill", accessibilityDescription: "Codex")
        button.imagePosition = .imageLeft
        button.title = " --"
        button.toolTip = "Codex 额度"

        statusItem.menu = makeStatusMenu()
        updateMenuState()
    }

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()

        let visibilityItem = NSMenuItem(
            title: "隐藏浮窗",
            action: #selector(toggleHUDWindow(_:)),
            keyEquivalent: ""
        )
        visibilityItem.target = self
        menu.addItem(visibilityItem)
        hudVisibilityMenuItem = visibilityItem

        let refreshItem = NSMenuItem(
            title: "刷新额度",
            action: #selector(refreshQuotaFromMenu(_:)),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        let settingsItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu(title: "设置")

        let colorHeader = NSMenuItem(title: "浮窗颜色", action: nil, keyEquivalent: "")
        colorHeader.isEnabled = false
        settingsMenu.addItem(colorHeader)

        for colorChoice in HUDAppearance.ColorChoice.allCases {
            let item = NSMenuItem(
                title: colorChoice.title,
                action: #selector(selectHUDColor(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = colorChoice.rawValue
            settingsMenu.addItem(item)
            colorMenuItems[colorChoice] = item
        }

        settingsMenu.addItem(.separator())

        let opacityHeader = NSMenuItem(title: "透明度", action: nil, keyEquivalent: "")
        opacityHeader.isEnabled = false
        settingsMenu.addItem(opacityHeader)

        for opacity in HUDAppearance.opacityChoices {
            let item = NSMenuItem(
                title: "\(Int((opacity * 100).rounded()))%",
                action: #selector(selectHUDOpacity(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = NSNumber(value: opacity)
            settingsMenu.addItem(item)
            opacityMenuItems[opacity] = item
        }

        menu.setSubmenu(settingsMenu, for: settingsItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitFromMenu(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func configureLifecycleMonitor() {
        lifecycleMonitor.onCodexStarted = { [weak self] in
            self?.codexDidStart()
        }

        lifecycleMonitor.onCodexStopped = { [weak self] in
            self?.codexDidStop()
        }
    }

    private func updateStatusTitle(with state: RateLimitDisplayState) {
        guard let button = statusItem.button else {
            return
        }

        var titleParts: [String] = []
        var tooltipParts: [String] = []

        if let fiveHour = state.fiveHour {
            titleParts.append("\(fiveHour.shortTitle) \(fiveHour.remainingText)")
            tooltipParts.append("5 小时剩余 \(fiveHour.remainingText)")
        } else if let resetCredits = state.resetCredits, resetCredits.availableCount > 0 {
            titleParts.append("重置\(resetCredits.availableCount)")
            tooltipParts.append("可重置 \(resetCredits.availableCount) 次，\(resetCredits.expirationText)")
        }

        if let weekly = state.weekly {
            titleParts.append("\(weekly.shortTitle) \(weekly.remainingText)")
            tooltipParts.append("周限额剩余 \(weekly.remainingText)")
        }

        if !titleParts.isEmpty {
            button.title = " \(titleParts.joined(separator: "  "))"
            button.toolTip = "Codex 额度：\(tooltipParts.joined(separator: "，"))"
        } else if state.isRefreshing {
            button.title = " ..."
            button.toolTip = "Codex 额度：正在刷新"
        } else {
            button.title = " --"
            button.toolTip = state.errorMessage ?? "Codex 额度"
        }
    }

    @objc private func toggleHUDWindow(_ sender: AnyObject?) {
        if hudWindow.isVisible {
            hudWindow.orderOut(sender)
        } else {
            showHUDWindow()
        }
        updateMenuState()
    }

    private func showHUDWindow() {
        hudWindow.orderFrontPinned()
        hudController.activateTouchBar()
        updateMenuState()
    }

    private func codexDidStart() {
        NSApp.setActivationPolicy(.accessory)
        store.start()
        showHUDWindow()
    }

    private func codexDidStop() {
        hudWindow.orderOut(nil)
        store.stop()
        NSApp.terminate(nil)
    }

    private func refreshQuotaNow() {
        store.start()
    }

    private func quitFromHUD() {
        quitApp()
    }

    @objc private func refreshQuotaFromMenu(_ sender: AnyObject?) {
        refreshQuotaNow()
    }

    @objc private func quitFromMenu(_ sender: AnyObject?) {
        quitApp()
    }

    @objc private func selectHUDColor(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let colorChoice = HUDAppearance.ColorChoice(rawValue: rawValue) else {
            return
        }

        hudAppearance.colorChoice = colorChoice
        applyHUDAppearance()
    }

    @objc private func selectHUDOpacity(_ sender: NSMenuItem) {
        guard let number = sender.representedObject as? NSNumber else {
            return
        }

        hudAppearance.opacity = number.doubleValue
        applyHUDAppearance()
    }

    private func applyHUDAppearance() {
        hudAppearance.save()
        hudController.updateAppearance(hudAppearance)
        updateMenuState()
    }

    private func updateMenuState() {
        hudVisibilityMenuItem?.title = hudWindow.isVisible ? "隐藏浮窗" : "显示浮窗"

        for (colorChoice, item) in colorMenuItems {
            item.state = colorChoice == hudAppearance.colorChoice ? .on : .off
        }

        for (opacity, item) in opacityMenuItems {
            item.state = abs(opacity - hudAppearance.opacity) < 0.001 ? .on : .off
        }
    }

    private func quitApp() {
        CodexAutoLauncher.markManualQuit()
        hudWindow.orderOut(nil)
        lifecycleMonitor.stop()
        store.stop()
        NSApp.terminate(nil)
    }
}

import AppKit

final class CompactHUDViewController: NSViewController, NSTouchBarDelegate {
    private enum TouchBarIdentifiers {
        static let touchBar = NSTouchBar.CustomizationIdentifier("com.jackchen.TouchBarCodexToken.compactHUD.touchBar")
        static let limits = NSTouchBarItem.Identifier("com.jackchen.TouchBarCodexToken.compactHUD.limits")
    }

    private let hudView: CompactQuotaHUDView
    private lazy var touchBarView = TouchBarRateLimitsView(closeTarget: self, closeAction: #selector(quitClicked))
    private var currentState = RateLimitDisplayState.initial
    private let onRefresh: () -> Void
    private let onQuit: () -> Void

    init(initialAppearance: HUDAppearance, onRefresh: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onRefresh = onRefresh
        self.onQuit = onQuit
        self.hudView = CompactQuotaHUDView(
            initialAppearance: initialAppearance,
            onRefresh: onRefresh,
            onQuit: onQuit
        )
        super.init(nibName: nil, bundle: nil)
        self.hudView.touchBarProvider = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = hudView
        view.frame = NSRect(x: 0, y: 0, width: 226, height: 34)
        update(with: currentState)
    }

    override func makeTouchBar() -> NSTouchBar? {
        makeQuotaTouchBar()
    }

    func makeQuotaTouchBar() -> NSTouchBar {
        let touchBar = NSTouchBar()
        touchBar.customizationIdentifier = TouchBarIdentifiers.touchBar
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [TouchBarIdentifiers.limits]
        return touchBar
    }

    func activateTouchBar() {
        hudView.activateTouchBar()
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case TouchBarIdentifiers.limits:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = touchBarView
            return item
        default:
            return nil
        }
    }

    func update(with state: RateLimitDisplayState) {
        currentState = state

        guard isViewLoaded else {
            return
        }

        hudView.update(with: state)
        touchBarView.update(with: state)
    }

    func updateAppearance(_ appearance: HUDAppearance) {
        hudView.updateAppearance(appearance)
    }

    @objc private func quitClicked() {
        onQuit()
    }
}

final class CompactQuotaHUDView: NSView {
    weak var touchBarProvider: CompactHUDViewController?

    private let fiveHourItem = CompactQuotaItemView(title: "5h")
    private let weeklyItem = CompactQuotaItemView(title: "7d")
    private let refreshButton = CompactIconButton(
        symbolName: "arrow.clockwise",
        accessibilityLabel: "刷新额度"
    )
    private let quitButton = CompactIconButton(
        symbolName: "xmark",
        accessibilityLabel: "退出额度条"
    )
    private let onRefresh: () -> Void
    private let onQuit: () -> Void
    private var hudAppearance: HUDAppearance

    init(initialAppearance: HUDAppearance, onRefresh: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onRefresh = onRefresh
        self.onQuit = onQuit
        self.hudAppearance = initialAppearance
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var mouseDownCanMoveWindow: Bool {
        true
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func becomeFirstResponder() -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        activateTouchBar()
        super.mouseDown(with: event)
    }

    override func makeTouchBar() -> NSTouchBar? {
        touchBarProvider?.makeQuotaTouchBar()
    }

    func activateTouchBar() {
        window?.makeFirstResponder(self)
        touchBar = nil
        touchBar = makeTouchBar()
    }

    func update(with state: RateLimitDisplayState) {
        let hasError = state.errorMessage != nil && state.fiveHour == nil && state.weekly == nil
        fiveHourItem.update(with: state.fiveHour, hasError: hasError)
        weeklyItem.update(with: state.weekly, hasError: hasError)
        toolTip = state.statusText
    }

    func updateAppearance(_ appearance: HUDAppearance) {
        self.hudAppearance = appearance
        layer?.backgroundColor = appearance.backgroundColor.cgColor
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = hudAppearance.backgroundColor.cgColor
        layer?.cornerRadius = 17
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = false

        refreshButton.target = self
        refreshButton.action = #selector(refreshClicked)
        quitButton.target = self
        quitButton.action = #selector(quitClicked)

        let stack = NSStackView(views: [fiveHourItem, weeklyItem, refreshButton, quitButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 8

        addSubview(stack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 226),
            heightAnchor.constraint(equalToConstant: 34),
            fiveHourItem.widthAnchor.constraint(equalToConstant: 64),
            weeklyItem.widthAnchor.constraint(equalToConstant: 64),
            refreshButton.widthAnchor.constraint(equalToConstant: 20),
            refreshButton.heightAnchor.constraint(equalToConstant: 20),
            quitButton.widthAnchor.constraint(equalToConstant: 20),
            quitButton.heightAnchor.constraint(equalToConstant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func refreshClicked() {
        onRefresh()
    }

    @objc private func quitClicked() {
        onQuit()
    }
}

private final class CompactQuotaItemView: NSView {
    private let dotView = CompactStatusDotView()
    private let label = NSTextField(labelWithString: "-- --")
    private let title: String

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with meter: LimitMeter?, hasError: Bool) {
        guard let meter else {
            label.stringValue = "\(title) --"
            label.textColor = NSColor.white.withAlphaComponent(0.62)
            dotView.color = hasError ? NSColor.systemRed : NSColor.white.withAlphaComponent(0.28)
            return
        }

        let remaining = Int(meter.remainingPercent.rounded())
        label.stringValue = "\(title) \(remaining)%"
        label.textColor = .white
        dotView.color = color(for: remaining)
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        label.lineBreakMode = .byClipping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = NSStackView(views: [dotView, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6

        addSubview(stack)

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func color(for remaining: Int) -> NSColor {
        if remaining <= 20 {
            return NSColor.systemRed
        }
        if remaining <= 45 {
            return NSColor.systemYellow
        }
        return NSColor.systemGreen
    }
}

private final class CompactIconButton: NSButton {
    init(symbolName: String, accessibilityLabel: String) {
        super.init(frame: .zero)

        image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyDown
        isBordered = false
        bezelStyle = .regularSquare
        setButtonType(.momentaryChange)
        contentTintColor = NSColor.white.withAlphaComponent(0.88)
        toolTip = accessibilityLabel
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CompactStatusDotView: NSView {
    var color = NSColor.systemGreen {
        didSet {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        color.setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).fill()
    }
}

import AppKit

final class TouchBarRateLimitsView: NSView {
    private let closeButton = NSButton()
    private let codexIconView = NSImageView()
    private let fiveHourRow = TouchBarLimitRow(title: "5 小时")
    private let weeklyRow = TouchBarLimitRow(title: "周限额")

    init(closeTarget: AnyObject, closeAction: Selector) {
        super.init(frame: .zero)
        closeButton.target = closeTarget
        closeButton.action = closeAction
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with state: RateLimitDisplayState) {
        fiveHourRow.update(with: state.fiveHour)
        weeklyRow.update(with: state.weekly)
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        closeButton.title = "×"
        closeButton.bezelStyle = .circular
        closeButton.font = .systemFont(ofSize: 19, weight: .semibold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        codexIconView.image = Self.codexIcon()
        codexIconView.imageAlignment = .alignCenter
        codexIconView.imageScaling = .scaleProportionallyUpOrDown
        codexIconView.translatesAutoresizingMaskIntoConstraints = false
        codexIconView.toolTip = "Codex"

        let rows = NSStackView(views: [fiveHourRow, weeklyRow])
        rows.translatesAutoresizingMaskIntoConstraints = false
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 1

        let content = NSStackView(views: [closeButton, codexIconView, rows])
        content.translatesAutoresizingMaskIntoConstraints = false
        content.orientation = .horizontal
        content.alignment = .centerY
        content.spacing = 12

        addSubview(content)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 520),
            heightAnchor.constraint(equalToConstant: 30),
            closeButton.widthAnchor.constraint(equalToConstant: 34),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            codexIconView.widthAnchor.constraint(equalToConstant: 28),
            codexIconView.heightAnchor.constraint(equalToConstant: 24),
            fiveHourRow.widthAnchor.constraint(equalToConstant: 402),
            weeklyRow.widthAnchor.constraint(equalToConstant: 402),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private static func codexIcon() -> NSImage {
        let iconPath = "/Applications/Codex.app/Contents/Resources/icon.icns"
        if let image = NSImage(contentsOfFile: iconPath) {
            image.size = NSSize(width: 24, height: 24)
            return image
        }

        let image = NSWorkspace.shared.icon(forFile: "/Applications/Codex.app")
        image.size = NSSize(width: 24, height: 24)
        return image
    }
}

private final class TouchBarLimitRow: NSView {
    private let titleLabel: NSTextField
    private let batteryBar = SegmentedBatteryBar()
    private let remainingLabel = NSTextField(labelWithString: "剩余 --")
    private let resetLabel = NSTextField(labelWithString: "-- 重置")

    init(title: String) {
        self.titleLabel = NSTextField(labelWithString: title)
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with meter: LimitMeter?) {
        guard let meter else {
            batteryBar.remainingPercent = 0
            batteryBar.isDimmed = true
            remainingLabel.stringValue = "剩余 --"
            resetLabel.stringValue = "-- 重置"
            return
        }

        batteryBar.remainingPercent = meter.remainingPercent
        batteryBar.isDimmed = false
        remainingLabel.stringValue = "剩余 \(meter.remainingText)"
        resetLabel.stringValue = meter.resetText
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .right

        remainingLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        remainingLabel.textColor = .labelColor
        remainingLabel.lineBreakMode = .byTruncatingTail

        resetLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        resetLabel.textColor = .labelColor
        resetLabel.lineBreakMode = .byTruncatingTail

        let row = NSStackView(views: [titleLabel, batteryBar, remainingLabel, resetLabel])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        addSubview(row)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 13),
            titleLabel.widthAnchor.constraint(equalToConstant: 48),
            batteryBar.widthAnchor.constraint(equalToConstant: 175),
            batteryBar.heightAnchor.constraint(equalToConstant: 11),
            remainingLabel.widthAnchor.constraint(equalToConstant: 76),
            resetLabel.widthAnchor.constraint(equalToConstant: 82),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

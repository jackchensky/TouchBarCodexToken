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
        if let fiveHour = state.fiveHour {
            fiveHourRow.isHidden = false
            fiveHourRow.updateLimit(
                title: "5 小时",
                meter: fiveHour,
                usageText: state.tokenUsage?.yesterdayText ?? "昨日 --"
            )
        } else if let resetCredits = state.resetCredits, resetCredits.availableCount > 0 {
            fiveHourRow.isHidden = false
            fiveHourRow.updateResetCredits(
                resetCredits,
                usageText: state.tokenUsage?.yesterdayText ?? "昨日 --"
            )
        } else if state.lastUpdated != nil {
            fiveHourRow.isHidden = true
        } else {
            fiveHourRow.isHidden = false
            fiveHourRow.updatePlaceholder(title: "5 小时", usageText: "昨日 --")
        }

        if let weekly = state.weekly {
            weeklyRow.isHidden = false
            weeklyRow.updateLimit(
                title: "周限额",
                meter: weekly,
                usageText: state.tokenUsage?.cumulativeText ?? "累计 --"
            )
        } else if state.lastUpdated != nil {
            weeklyRow.isHidden = true
        } else {
            weeklyRow.isHidden = false
            weeklyRow.updatePlaceholder(title: "周限额", usageText: "累计 --")
        }
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
        content.setCustomSpacing(2, after: codexIconView)

        addSubview(content)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 620),
            heightAnchor.constraint(equalToConstant: 30),
            closeButton.widthAnchor.constraint(equalToConstant: 34),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            codexIconView.widthAnchor.constraint(equalToConstant: 34),
            codexIconView.heightAnchor.constraint(equalToConstant: 30),
            fiveHourRow.widthAnchor.constraint(equalToConstant: 502),
            weeklyRow.widthAnchor.constraint(equalToConstant: 502),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private static func codexIcon() -> NSImage {
        let iconPaths = [
            "/Applications/ChatGPT.app/Contents/Resources/icon-codex-light.png",
            "/Applications/ChatGPT.app/Contents/Resources/icon-codex-dark-color.png",
            "/Applications/Codex.app/Contents/Resources/icon.icns"
        ]

        for path in iconPaths {
            if let image = NSImage(contentsOfFile: path) {
                image.size = NSSize(width: 30, height: 30)
                return image
            }
        }

        let appPaths = ["/Applications/ChatGPT.app", "/Applications/Codex.app"]
        for path in appPaths where FileManager.default.fileExists(atPath: path) {
            let image = NSWorkspace.shared.icon(forFile: path)
            image.size = NSSize(width: 30, height: 30)
            return image
        }

        let bundledIconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns")
        let image = bundledIconPath.flatMap(NSImage.init(contentsOfFile:))
            ?? NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "Codex")
            ?? NSImage(size: NSSize(width: 30, height: 30))
        image.size = NSSize(width: 30, height: 30)
        return image
    }
}

private final class TouchBarLimitRow: NSView {
    private let titleLabel: NSTextField
    private let batteryBar = SegmentedBatteryBar()
    private let creditsIndicatorLabel = NSTextField(labelWithString: "")
    private let remainingLabel = NSTextField(labelWithString: "剩余 --")
    private let resetLabel = NSTextField(labelWithString: "-- 重置")
    private let separatorLabel = NSTextField(labelWithString: "|")
    private let usageLabel = NSTextField(labelWithString: "--")

    init(title: String) {
        self.titleLabel = NSTextField(labelWithString: title)
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLimit(title: String, meter: LimitMeter, usageText: String) {
        titleLabel.stringValue = title
        batteryBar.isHidden = false
        creditsIndicatorLabel.isHidden = true
        batteryBar.remainingPercent = meter.remainingPercent
        batteryBar.isDimmed = false
        remainingLabel.stringValue = "剩余 \(meter.remainingText)"
        resetLabel.stringValue = meter.resetText
        usageLabel.stringValue = usageText
    }

    func updateResetCredits(_ resetCredits: ResetCreditSummary, usageText: String) {
        titleLabel.stringValue = "重置券"
        batteryBar.isHidden = true
        creditsIndicatorLabel.isHidden = false
        creditsIndicatorLabel.stringValue = Self.creditIndicator(count: resetCredits.availableCount)
        remainingLabel.stringValue = resetCredits.availableText
        resetLabel.stringValue = resetCredits.expirationText
        usageLabel.stringValue = usageText
    }

    func updatePlaceholder(title: String, usageText: String) {
        titleLabel.stringValue = title
        batteryBar.isHidden = false
        creditsIndicatorLabel.isHidden = true
        batteryBar.remainingPercent = 0
        batteryBar.isDimmed = true
        remainingLabel.stringValue = "剩余 --"
        resetLabel.stringValue = "-- 重置"
        usageLabel.stringValue = usageText
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .left

        creditsIndicatorLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        creditsIndicatorLabel.textColor = .systemTeal
        creditsIndicatorLabel.alignment = .left
        creditsIndicatorLabel.lineBreakMode = .byClipping
        creditsIndicatorLabel.isHidden = true

        remainingLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        remainingLabel.textColor = .labelColor
        remainingLabel.lineBreakMode = .byTruncatingTail

        resetLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        resetLabel.textColor = .labelColor
        resetLabel.lineBreakMode = .byTruncatingTail

        separatorLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        separatorLabel.textColor = .labelColor
        separatorLabel.alignment = .center

        usageLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        usageLabel.textColor = .labelColor
        usageLabel.lineBreakMode = .byTruncatingTail

        let statusContainer = NSView()
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        batteryBar.translatesAutoresizingMaskIntoConstraints = false
        creditsIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(batteryBar)
        statusContainer.addSubview(creditsIndicatorLabel)

        let row = NSStackView(views: [
            titleLabel,
            statusContainer,
            remainingLabel,
            resetLabel,
            separatorLabel,
            usageLabel
        ])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 8
        row.setCustomSpacing(4, after: titleLabel)
        row.setCustomSpacing(0, after: remainingLabel)
        row.setCustomSpacing(4, after: resetLabel)
        row.setCustomSpacing(4, after: separatorLabel)

        addSubview(row)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 13),
            titleLabel.widthAnchor.constraint(equalToConstant: 42),
            statusContainer.widthAnchor.constraint(equalToConstant: 175),
            statusContainer.heightAnchor.constraint(equalToConstant: 11),
            batteryBar.widthAnchor.constraint(equalToConstant: 175),
            batteryBar.heightAnchor.constraint(equalToConstant: 11),
            batteryBar.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor),
            batteryBar.topAnchor.constraint(equalTo: statusContainer.topAnchor),
            creditsIndicatorLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 5),
            creditsIndicatorLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusContainer.trailingAnchor),
            creditsIndicatorLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            remainingLabel.widthAnchor.constraint(equalToConstant: 58),
            resetLabel.widthAnchor.constraint(equalToConstant: 125),
            separatorLabel.widthAnchor.constraint(equalToConstant: 8),
            usageLabel.widthAnchor.constraint(equalToConstant: 66),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private static func creditIndicator(count: Int) -> String {
        if count <= 5 {
            return Array(repeating: "●", count: max(0, count)).joined(separator: "  ")
        }
        return "●  × \(count)"
    }
}

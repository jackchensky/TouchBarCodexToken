import Foundation

struct GetAccountRateLimitsResponse: Codable {
    let rateLimits: RateLimitSnapshot
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?
}

struct RateLimitSnapshot: Codable {
    let limitId: String?
    let limitName: String?
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
}

struct RateLimitWindow: Codable {
    let usedPercent: Double
    let windowDurationMins: Double?
    let resetsAt: Double?
}

struct LimitMeter: Equatable {
    let title: String
    let shortTitle: String
    let usedPercent: Double
    let remainingPercent: Double
    let resetDate: Date?
    let durationMinutes: Double?

    var remainingText: String {
        "\(Int(remainingPercent.rounded()))%"
    }

    var resetText: String {
        guard let resetDate else {
            return "重置 --"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current

        if Calendar.current.isDateInToday(resetDate) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "E HH:mm"
        }

        return "\(formatter.string(from: resetDate)) 重置"
    }

    init(title: String, shortTitle: String, window: RateLimitWindow) {
        self.title = title
        self.shortTitle = shortTitle
        self.usedPercent = window.usedPercent
        self.remainingPercent = max(0, min(100, 100 - window.usedPercent))
        self.resetDate = Self.date(fromEpoch: window.resetsAt)
        self.durationMinutes = window.windowDurationMins
    }

    private static func date(fromEpoch value: Double?) -> Date? {
        guard let value else {
            return nil
        }

        let seconds = value > 10_000_000_000 ? value / 1000 : value
        return Date(timeIntervalSince1970: seconds)
    }
}

struct RateLimitDisplayState: Equatable {
    var fiveHour: LimitMeter?
    var weekly: LimitMeter?
    var isRefreshing: Bool
    var lastUpdated: Date?
    var errorMessage: String?

    static let initial = RateLimitDisplayState(
        fiveHour: nil,
        weekly: nil,
        isRefreshing: false,
        lastUpdated: nil,
        errorMessage: nil
    )

    var statusText: String {
        if let errorMessage {
            return errorMessage
        }

        if isRefreshing {
            return lastUpdated == nil ? "正在读取本机 Codex app-server..." : "正在刷新，保留上一组数据"
        }

        guard let lastUpdated else {
            return "尚未读取额度"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "上次更新 \(formatter.string(from: lastUpdated))"
    }
}

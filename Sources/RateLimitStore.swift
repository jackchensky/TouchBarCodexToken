import Foundation

protocol RateLimitStoreDelegate: AnyObject {
    func rateLimitStore(_ store: RateLimitStore, didUpdate state: RateLimitDisplayState)
}

final class RateLimitStore {
    weak var delegate: RateLimitStoreDelegate?

    private let client = CodexAppServerClient()
    private var timer: Timer?
    private var state = RateLimitDisplayState.initial
    private var refreshInFlight = false
    private var isStarted = false

    func start() {
        guard !isStarted else {
            refresh()
            return
        }
        isStarted = true

        client.onRateLimitsUpdated = { [weak self] in
            self?.refresh()
        }

        client.start { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                self.refresh()
                self.startTimer()
            case .failure(let error):
                self.publishError(error.localizedDescription)
            }
        }
    }

    func stop() {
        isStarted = false
        refreshInFlight = false
        timer?.invalidate()
        timer = nil
        client.stop()
    }

    func refresh() {
        guard !refreshInFlight else {
            return
        }

        refreshInFlight = true
        state.isRefreshing = true
        state.errorMessage = nil
        publish()

        client.readRateLimits { [weak self] result in
            guard let self else {
                return
            }

            self.refreshInFlight = false

            switch result {
            case .success(let response):
                self.apply(response)
            case .failure(let error):
                self.state.isRefreshing = false
                self.state.errorMessage = error.localizedDescription
                self.publish()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func apply(_ response: GetAccountRateLimitsResponse) {
        let snapshot = response.rateLimitsByLimitId?["codex"] ?? response.rateLimits
        let windows = classifyWindows(primary: snapshot.primary, secondary: snapshot.secondary)

        state.fiveHour = windows.fiveHour
        state.weekly = windows.weekly
        state.tokenUsage = LocalTokenUsageReader.read()
        state.isRefreshing = false
        state.lastUpdated = Date()
        state.errorMessage = nil
        publish()
    }

    private func classifyWindows(primary: RateLimitWindow?, secondary: RateLimitWindow?) -> (fiveHour: LimitMeter?, weekly: LimitMeter?) {
        let candidates = [primary, secondary].compactMap { $0 }

        let fiveHourWindow = candidates.first { window in
            guard let duration = window.windowDurationMins else {
                return false
            }
            return abs(duration - 300) < 30
        } ?? primary

        let weeklyWindow = candidates.first { window in
            guard let duration = window.windowDurationMins else {
                return false
            }
            return duration >= 7 * 24 * 60 - 60
        } ?? secondary

        let fiveHour = fiveHourWindow.map {
            LimitMeter(title: "5 小时", shortTitle: "5h", window: $0)
        }

        let weekly = weeklyWindow.map {
            LimitMeter(title: "周限额", shortTitle: "W", window: $0)
        }

        return (fiveHour, weekly)
    }

    private func publishError(_ message: String) {
        state.isRefreshing = false
        state.errorMessage = message
        publish()
    }

    private func publish() {
        delegate?.rateLimitStore(self, didUpdate: state)
    }
}

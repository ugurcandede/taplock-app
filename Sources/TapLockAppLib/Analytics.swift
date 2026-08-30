import Foundation

/// One anonymous ping per day to Google Analytics (Measurement Protocol):
/// a random install id and the last used mode, nothing else. Off when
/// "send anonymous usage stats" is unchecked. The Measurement Protocol does
/// not derive geography from the IP, and no other identifier leaves the Mac.
public enum Analytics {
    /// GA4 → Admin → Data streams → Measurement Protocol API secrets.
    /// The property is shared across apps; appName is the discriminator.
    private static let measurementID = "G-DCYDCWCN8V"
    private static let apiSecret = "RzYiYu4ISFCAwL6K4ZuiUA"
    private static let appName = "taplock"

    public static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "analyticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "analyticsEnabled") }
    }

    /// Mode is not a persistent setting here, so the ping reports the mode
    /// of the last started session — "none" until one has run.
    public static var lastUsedMode: String {
        get { UserDefaults.standard.string(forKey: "analyticsLastMode") ?? "none" }
        set { UserDefaults.standard.set(newValue, forKey: "analyticsLastMode") }
    }

    public static func start() {
        pingIfDue()
        // The app can run for weeks between launches; a timer keeps daily
        // actives honest. pingIfDue itself sends at most once per day.
        Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { _ in
            pingIfDue()
        }
    }

    private static func pingIfDue() {
        guard !measurementID.isEmpty, !apiSecret.isEmpty, enabled else { return }
        let now = Date()
        guard lastPing != day(now) else { return }
        for date in unsentDates(now: now) { send(date, backdated: date != now) }
    }

    /// Days missed offline are backfilled with a backdated timestamp, which
    /// GA accepts up to 72 hours into the past — so at most the two previous
    /// days are recoverable; older gaps stay lost.
    private static func unsentDates(now: Date) -> [Date] {
        guard let lastSent = lastPing else { return [now] }
        var dates: [Date] = []
        for offset in [2, 1] {
            guard let past = Calendar.current.date(byAdding: .day, value: -offset, to: now) else { continue }
            if day(past) > lastSent { dates.append(past) }
        }
        dates.append(now)
        return dates
    }

    private static func send(_ date: Date, backdated: Bool) {
        var request = URLRequest(url: URL(string:
            "https://www.google-analytics.com/mp/collect?measurement_id=\(measurementID)&api_secret=\(apiSecret)")!)
        request.httpMethod = "POST"

        // session_id and engagement_time_msec are required for the ping to
        // count as an active user in GA4 reports, not just an event.
        var body: [String: Any] = [
            "client_id": clientID,
            "events": [[
                "name": "daily_ping",
                "params": [
                    "app_name": appName,
                    // "backfill" means the day was spent offline and the
                    // ping was recovered later; "live" went out same-day.
                    "ping_type": backdated ? "backfill" : "live",
                    "mode": lastUsedMode,
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev",
                    "session_id": String(Int(date.timeIntervalSince1970)),
                    "engagement_time_msec": 100
                ]
            ]]
        ]
        if backdated { body["timestamp_micros"] = Int(date.timeIntervalSince1970 * 1_000_000) }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // The day is marked sent only once Google answers — an unreachable
        // network leaves lastPing untouched, so the next timer tick retries
        // and backfills what it can.
        let sentDay = day(date)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else { return }
            if sentDay > (lastPing ?? "") { lastPing = sentDay }
        }.resume()
    }

    /// yyyy-MM-dd of the newest acknowledged ping.
    private static var lastPing: String? {
        get { UserDefaults.standard.string(forKey: "lastAnalyticsPing") }
        set { UserDefaults.standard.set(newValue, forKey: "lastAnalyticsPing") }
    }

    /// Random id minted on first use — the only identifier analytics sends.
    private static var clientID: String {
        if let id = UserDefaults.standard.string(forKey: "analyticsClientID") { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "analyticsClientID")
        return id
    }

    private static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

import Foundation

public struct AppUpdate: Equatable {
    public let version: String
    public let url: URL
}

/// Checks GitHub for a release newer than the running build.
///
/// Unauthenticated GitHub API calls are limited to 60 an hour per IP; the app
/// checks at launch and once a day, far below that. A dismissed version stays
/// hidden until a newer one is published.
///
/// Installs from Homebrew update themselves: `brew upgrade --cask` replaces the
/// bundle on disk, then the app quits and reopens itself. brew would normally
/// quit the app first (the cask's `uninstall quit:`), but it never quits an app
/// it finds among its own parent processes. Other installs get the release page.
///
/// App-agnostic on purpose: the per-app bits are the constants below.
public enum UpdateChecker {
    private static let repo = "ugurcandede/taplock-app"
    private static let cask = "taplock-app"
    private static let bundleID = "com.ugurcandede.taplock"

    public static func check(completion: @escaping (AppUpdate?) -> Void) {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let update = data.flatMap { parseRelease($0, currentVersion: Analytics.appVersion) }
            DispatchQueue.main.async { completion(update) }
        }.resume()
    }

    /// The Homebrew prefix managing this app, if it was installed as a cask.
    public static var brewPrefix: String? {
        ["/opt/homebrew", "/usr/local"].first { prefix in
            FileManager.default.isExecutableFile(atPath: "\(prefix)/bin/brew")
                && FileManager.default.fileExists(atPath: "\(prefix)/Caskroom/\(cask)")
        }
    }

    public static var logURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/\(cask)-update.log")
    }

    /// Runs the upgrade; `onFinished` (main queue) gets whether brew succeeded.
    /// Success with an unchanged `installedVersion` means brew had no newer
    /// version yet — the tap is bumped a few minutes after the GitHub release.
    public static func upgrade(prefix: String, onFinished: @escaping (_ succeeded: Bool) -> Void) {
        let log = logURL.path
        let script = """
            echo "--- $(date)" >> "\(log)"
            # brew's auto-update runs at most once a day, so the tap can still
            # hold the previous cask; refresh it first. Offline, try anyway.
            "\(prefix)/bin/brew" update --quiet >> "\(log)" 2>&1
            "\(prefix)/bin/brew" upgrade --cask \(cask) >> "\(log)" 2>&1
            """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        // Launched from Finder the app has no shell PATH; brew needs git and curl.
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "\(prefix)/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOMEBREW_NO_ENV_HINTS"] = "1"
        process.environment = environment
        process.terminationHandler = { finished in
            let succeeded = finished.terminationStatus == 0
            DispatchQueue.main.async { onFinished(succeeded) }
        }
        do {
            try process.run()
        } catch {
            DispatchQueue.main.async { onFinished(false) }
        }
    }

    /// The version of the bundle on disk, read fresh — after an upgrade it
    /// differs from the one this process loaded at launch.
    public static var installedVersion: String? {
        let plist = Bundle.main.bundleURL.appendingPathComponent("Contents/Info.plist")
        return NSDictionary(contentsOf: plist)?["CFBundleShortVersionString"] as? String
    }

    /// Open the bundle again once this process has gone. Call right before quitting.
    public static func relaunchAfterExit() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done; open -b \(bundleID)"]
        try? process.run()
    }

    public static var dismissedVersion: String? {
        get { UserDefaults.standard.string(forKey: "updateDismissedVersion") }
        set { UserDefaults.standard.set(newValue, forKey: "updateDismissedVersion") }
    }

    /// The release in `data` if it is newer than `currentVersion` and not dismissed.
    static func parseRelease(_ data: Data, currentVersion: String) -> AppUpdate? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let page = (json["html_url"] as? String).flatMap(URL.init(string:))
        else { return nil }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        guard isNewer(version, than: currentVersion), version != dismissedVersion else { return nil }
        return AppUpdate(version: version, url: page)
    }

    /// Numeric dot-separated comparison: 1.10.0 is newer than 1.9.3.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

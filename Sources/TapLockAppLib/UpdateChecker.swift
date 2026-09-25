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
/// Installs from Homebrew update themselves: `brew upgrade --cask` quits the
/// app (the cask's `uninstall quit:`), installs the new build, and the shell
/// that ran it — which outlives us — opens the new one. Other installs get the
/// release page.
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

    /// Runs the upgrade in a shell that survives this process. A real upgrade
    /// quits us before the shell ends, so `onNotUpdated` (main queue) only runs
    /// when nothing was installed: `true` if brew had no newer version yet —
    /// the tap is bumped a few minutes after the GitHub release — `false` if
    /// it failed.
    public static func upgrade(prefix: String, onNotUpdated: @escaping (_ upToDate: Bool) -> Void) {
        let log = logURL.path
        let script = """
            echo "--- $(date)" >> "\(log)"
            "\(prefix)/bin/brew" upgrade --cask \(cask) >> "\(log)" 2>&1 || exit 1
            # Still running means brew installed nothing; opening would only
            # start a second copy if another one exists.
            kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null || open -b \(bundleID)
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
            let upToDate = finished.terminationStatus == 0
            DispatchQueue.main.async { onNotUpdated(upToDate) }
        }
        do {
            try process.run()
        } catch {
            DispatchQueue.main.async { onNotUpdated(false) }
        }
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

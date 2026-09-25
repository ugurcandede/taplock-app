import Foundation
import Testing
@testable import TapLockAppLib

@Suite("UpdateChecker")
struct UpdateCheckerTests {

    @Test func newerVersions() {
        #expect(UpdateChecker.isNewer("1.7.0", than: "1.6.2"))
        #expect(UpdateChecker.isNewer("1.10.0", than: "1.9.3"))
        #expect(UpdateChecker.isNewer("2.0", than: "1.9.9"))
    }

    @Test func notNewerVersions() {
        #expect(!UpdateChecker.isNewer("1.6.2", than: "1.6.2"))
        #expect(!UpdateChecker.isNewer("1.6.1", than: "1.6.2"))
        #expect(!UpdateChecker.isNewer("1.6", than: "1.6.0"))
    }

    @Test func parsesNewerRelease() {
        let json = #"{"tag_name":"v99.0.0","html_url":"https://github.com/ugurcandede/taplock-app/releases/tag/v99.0.0"}"#
        let update = UpdateChecker.parseRelease(Data(json.utf8), currentVersion: "1.6.2")
        #expect(update?.version == "99.0.0")
        #expect(update?.url.absoluteString == "https://github.com/ugurcandede/taplock-app/releases/tag/v99.0.0")
    }

    @Test func ignoresOlderOrSameRelease() {
        let json = #"{"tag_name":"v1.6.2","html_url":"https://example.com"}"#
        #expect(UpdateChecker.parseRelease(Data(json.utf8), currentVersion: "1.6.2") == nil)
    }

    @Test func ignoresMalformedResponse() {
        #expect(UpdateChecker.parseRelease(Data(#"{"message":"rate limited"}"#.utf8), currentVersion: "1.0.0") == nil)
    }
}

@Suite("Analytics")
struct AnalyticsTests {

    @Test func requestBodyShape() {
        let event: [String: Any] = ["id": "x", "name": "relax_start", "params": ["theme": "mini"], "ts": 123]
        let body = Analytics.requestBody(for: event)
        #expect(body["timestamp_micros"] as? Int == 123)
        #expect(body["client_id"] is String)
        let events = body["events"] as? [[String: Any]]
        #expect(events?.first?["name"] as? String == "relax_start")
        let props = body["user_properties"] as? [String: [String: Any]]
        #expect(props?["platform"]?["value"] as? String == "macos")
    }

    @Test func trackBeforeStartIsNoop() {
        let before = Analytics.queue.count
        Analytics.track("should_not_queue")
        #expect(Analytics.queue.count == before)
    }
}

@Suite("Analytics user properties")
struct AnalyticsUserPropertiesTests {

    @Test func boolsBecomeStrings() {
        Analytics.setUserProperties(["test_flag": true, "test_count": 3])
        let props = Analytics.userProperties()
        #expect(props["test_flag"] as? String == "true")
        #expect(props["test_count"] as? Int == 3)
    }
}

import Cocoa
import TapLockAppLib
import TapLockCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar only app
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()
        Analytics.start()

        // Check accessibility on launch
        if !InputBlocker.checkAccessibility() {
            InputBlocker.requestAccessibility()
        }
    }
}

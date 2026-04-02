import Cocoa
import CleanLockCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar only app
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()

        // Check accessibility on launch
        if !InputBlocker.checkAccessibility() {
            InputBlocker.requestAccessibility()
        }
    }
}

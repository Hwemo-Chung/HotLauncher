import AppKit
import HotLauncher

final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configManager = ConfigManager()
        let appLauncher = AppLauncher()
        menuBarController = MenuBarController(
            configManager: configManager,
            appLauncher: appLauncher
        )
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()

import AppKit
import SwiftUI

@MainActor
public final class MenuBarController: NSObject, NSWindowDelegate {
    private let statusItem: NSStatusItem
    private let configManager: ConfigManager
    private let hotkeyManager: HotkeyManager
    private let appLauncher: AppLauncher
    private var settingsWindow: NSWindow?

    public init(configManager: ConfigManager, appLauncher: AppLauncher) {
        self.configManager = configManager
        self.appLauncher = appLauncher
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.hotkeyManager = HotkeyManager { slotId in
            guard let slot = configManager.slot(for: slotId), slot.isArmed else { return }
            Task {
                try? await appLauncher.launch(appPath: slot.appPath)
            }
        }
        super.init()
        setupStatusItem()
        registerAllHotkeys()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "command.square",
                accessibilityDescription: "HotLauncher"
            )
        }
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "HotLauncher", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        if let config = try? configManager.load() {
            let filled = config.slots.filter { !$0.appPath.isEmpty }
            for slot in filled {
                let item = NSMenuItem(
                    title: slot.label.isEmpty ? "Slot \(slot.id)" : slot.label,
                    action: #selector(launchFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = slot.id
                menu.addItem(item)
            }
            if !filled.isEmpty {
                menu.addItem(NSMenuItem.separator())
            }
        }

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let coffee = NSMenuItem(
            title: "개발자에게 커피한잔?",
            action: #selector(donate),
            keyEquivalent: ""
        )
        coffee.image = NSImage(
            systemSymbolName: "cup.and.saucer",
            accessibilityDescription: "Donate $1.99"
        )
        coffee.target = self
        menu.addItem(coffee)

        let quitItem = NSMenuItem(title: "Quit HotLauncher", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func launchFromMenu(_ sender: NSMenuItem) {
        guard let slot = configManager.slot(for: sender.tag) else { return }
        Task { try? await appLauncher.launch(appPath: slot.appPath) }
    }

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(
            configManager: configManager,
            onSave: { [weak self] in
                guard let self else { return [] }
                let errors = self.registerAllHotkeys()
                self.rebuildMenu()
                return errors
            }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 860),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.title = "HotLauncher Settings"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(calibratedWhite: 0.957, alpha: 1)
        window.minSize = NSSize(width: 640, height: 820)
        window.isReleasedWhenClosed = false
        window.delegate = self
        let hosting = NSHostingView(rootView: view)
        hosting.sizingOptions = []
        window.contentView = hosting
        window.setContentSize(NSSize(width: 720, height: 860))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    public func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
    }

    @objc private func donate() {
        NSWorkspace.shared.open(Donate.url)
    }

    @objc private func quit() {
        hotkeyManager.unregisterAll()
        NSApp.terminate(nil)
    }

    @discardableResult
    func registerAllHotkeys() -> [String] {
        hotkeyManager.unregisterAll()
        guard let config = try? configManager.load() else { return [] }
        let slots = paddedSlots(config.slots).filter(\.isArmed)
        var seen: Set<String> = []
        var errors: [String] = []
        for slot in slots {
            let combo = "\(slot.keyCode):\(slot.combinedCarbonModifiers)"
            let name = slot.label.isEmpty ? "Slot \(slot.id)" : slot.label
            if seen.contains(combo) {
                errors.append("Skipped duplicate shortcut \(slot.shortcutDisplay) on \(name).")
                continue
            }
            seen.insert(combo)
            if !hotkeyManager.register(slot: slot) {
                errors.append("Could not register \(slot.shortcutDisplay) for \(name).")
            }
        }
        return errors
    }
}

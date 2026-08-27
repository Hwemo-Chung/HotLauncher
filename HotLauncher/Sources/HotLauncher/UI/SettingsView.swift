import SwiftUI
import AppKit
import UniformTypeIdentifiers

private enum UI {
    static let canvas = Color(red: 0.957, green: 0.957, blue: 0.957)
    static let card = Color.white
    static let field = Color(red: 0.945, green: 0.945, blue: 0.945)
    static let ink = Color.black
    static let muted = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let line = Color.black.opacity(0.08)
    static let radius: CGFloat = 22
}

struct SettingsView: View {
    let configManager: ConfigManager
    let onSave: () -> [String]
    @State private var slots: [HotkeySlot] = paddedSlots([])
    @State private var page = 0
    @State private var launchAtLogin = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let pageSize = 10
    private var pageCount: Int { ConfigManager.maxSlots / pageSize }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            slotGrid
            pager
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .background(UI.canvas)
        .safeAreaInset(edge: .bottom, spacing: 14) {
            VStack(spacing: 12) {
                loginCard
                coffeeCard
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
            .background(UI.canvas)
        }
        .frame(minWidth: 640, minHeight: 780)
        .focusEffectDisabled()
        .onAppear {
            loadConfig()
            if page >= pageCount { page = 0 }
            launchAtLogin = LoginLaunch.isEnabled
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HotLauncher")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(UI.ink)
                Text("Shortcuts for the apps you actually use.")
                    .font(.system(size: 13))
                    .foregroundStyle(UI.muted)
            }
            Spacer()
            Text("\(slots.filter(\.isArmed).count)/\(ConfigManager.maxSlots)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(UI.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(UI.field))
        }
    }

    private var slotGrid: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 12) {
                    slotCard(at: pageIndices[row * 2])
                    slotCard(at: pageIndices[row * 2 + 1])
                }
            }
        }
    }

    private func slotCard(at index: Int) -> some View {
        SlotCard(
            slot: Binding(
                get: { slots[index] },
                set: { newVal in
                    slots[index] = newVal
                    saveConfig()
                }
            ),
            onPickApp: { pickApp(for: index) },
            onClear: {
                slots[index] = HotkeySlot.empty(id: slots[index].id)
                saveConfig()
            }
        )
    }

    private var pageIndices: [Int] {
        let start = page * pageSize
        return Array(start..<(start + pageSize))
    }

    private var pager: some View {
        HStack(spacing: 10) {
            Button {
                page = max(0, page - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(page == 0 ? UI.muted.opacity(0.4) : UI.ink)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(UI.field))
            }
            .buttonStyle(.plain)
            .disabled(page == 0)

            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(i == page ? UI.ink : UI.field)
                    .frame(width: 7, height: 7)
                    .onTapGesture { page = i }
            }

            Text("\(page + 1)/\(pageCount)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(UI.muted)

            Button {
                page = min(pageCount - 1, page + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(page == pageCount - 1 ? UI.muted.opacity(0.4) : UI.ink)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(UI.field))
            }
            .buttonStyle(.plain)
            .disabled(page == pageCount - 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var loginCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Launch at login")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(UI.ink)
                Text("Start HotLauncher when you log in.")
                    .font(.system(size: 12))
                    .foregroundStyle(UI.muted)
            }
            Spacer()
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(UI.ink)
                .accessibilityLabel("Launch at login")
                .onChange(of: launchAtLogin) { _, on in
                    do {
                        try LoginLaunch.setEnabled(on)
                    } catch {
                        launchAtLogin = LoginLaunch.isEnabled
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
        }
        .padding(16)
        .cardSurface()
    }

    private var coffeeCard: some View {
        Button(action: { NSWorkspace.shared.open(Donate.url) }) {
            HStack(spacing: 12) {
                Image(systemName: "mug.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(UI.ink)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(UI.field))
                VStack(alignment: .leading, spacing: 2) {
                    Text("개발자에게 커피한잔?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(UI.ink)
                    Text("$1.99 via PayPal")
                        .font(.system(size: 12))
                        .foregroundStyle(UI.muted)
                }
                Spacer()
                Text("Pay")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(UI.ink))
            }
            .padding(16)
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    private func loadConfig() {
        slots = paddedSlots((try? configManager.load())?.slots ?? [])
    }

    private func saveConfig() {
        if let pair = firstDuplicateArmedPair(slots) {
            let a = pair.0.label.isEmpty ? "Slot \(pair.0.id)" : pair.0.label
            let b = pair.1.label.isEmpty ? "Slot \(pair.1.id)" : pair.1.label
            errorMessage = "Duplicate shortcut \(pair.0.shortcutDisplay) on \(a) and \(b)."
            showError = true
        }
        let config = Config(version: 1, slots: slots)
        do {
            try configManager.save(config)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }
        let registerErrors = onSave()
        if !registerErrors.isEmpty {
            errorMessage = registerErrors.joined(separator: "\n")
            showError = true
        }
    }

    private func pickApp(for index: Int) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            slots[index].appPath = url.path
            slots[index].label = url.deletingPathExtension().lastPathComponent
            saveConfig()
        }
    }
}

private struct SlotCard: View {
    @Binding var slot: HotkeySlot
    let onPickApp: () -> Void
    let onClear: () -> Void
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                appIcon
                VStack(alignment: .leading, spacing: 1) {
                    Text(slot.label.isEmpty ? "Empty" : slot.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(UI.ink)
                        .lineLimit(1)
                    Text(slot.appPath.isEmpty ? "No app" : URL(fileURLWithPath: slot.appPath).lastPathComponent)
                        .font(.system(size: 11))
                        .foregroundStyle(UI.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(UI.muted)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(UI.field))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear slot")
            }

            HStack(spacing: 6) {
                Button(isRecording ? "Press..." : (slot.modifiers.isEmpty ? "Key" : slot.shortcutDisplay)) {
                    isRecording = true
                }
                .buttonStyle(CapsuleChipStyle(filled: isRecording))
                .accessibilityLabel(isRecording ? "Press keys" : "Record shortcut")
                .accessibilityIdentifier("record-shortcut")

                Button("App") { onPickApp() }
                    .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(12)
        .cardSurface()
        .onChange(of: isRecording) { _, recording in
            if recording { startMonitor() } else { stopMonitor() }
        }
        .onDisappear { stopMonitor() }
    }

    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(UI.field)
            if slot.appPath.isEmpty {
                Image(systemName: "app.dashed")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(UI.muted)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: slot.appPath))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
        }
        .frame(width: 32, height: 32)
        .clipped()
    }

    private func startMonitor() {
        stopMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let result = interpretHotkeyPress(
                keyCode: UInt32(event.keyCode),
                modifiers: modifiersFrom(event.modifierFlags)
            )
            switch result {
            case .captured(let code, let mods):
                DispatchQueue.main.async {
                    slot.keyCode = code
                    slot.modifiers = mods
                    isRecording = false
                }
                return nil
            case .cancel:
                DispatchQueue.main.async { isRecording = false }
                return nil
            case .ignore:
                return event
            }
        }
    }

    private func stopMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

private struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(UI.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white)
                    .overlay(Capsule().stroke(UI.line, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct CapsuleChipStyle: ButtonStyle {
    var filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: filled ? .semibold : .medium))
            .foregroundStyle(filled ? Color.white : UI.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(filled ? UI.ink.opacity(configuration.isPressed ? 0.75 : 1) : UI.field)
            )
            .opacity(configuration.isPressed && !filled ? 0.65 : 1)
    }
}

private extension View {
    func cardSurface() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: UI.radius, style: .continuous)
                    .fill(UI.card)
                    .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
            )
    }
}

private func modifiersFrom(_ flags: NSEvent.ModifierFlags) -> [Modifier] {
    var mods: [Modifier] = []
    if flags.contains(.command) { mods.append(.command) }
    if flags.contains(.option) { mods.append(.option) }
    if flags.contains(.control) { mods.append(.control) }
    if flags.contains(.shift) { mods.append(.shift) }
    return mods
}

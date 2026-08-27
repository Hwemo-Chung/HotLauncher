import Testing
@testable import HotLauncher

@Test func registerTracksSlot() {
    let mgr = HotkeyManager(onHotkey: { _ in }, usesCarbon: false)
    let slot = HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    mgr.register(slot: slot)
    #expect(mgr.registeredSlotIds.contains(1))
}

@Test func unregisterRemovesSlot() {
    let mgr = HotkeyManager(onHotkey: { _ in }, usesCarbon: false)
    let slot = HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    mgr.register(slot: slot)
    mgr.unregister(slotId: 1)
    #expect(!mgr.registeredSlotIds.contains(1))
}

@Test func unregisterAllClearsAll() {
    let mgr = HotkeyManager(onHotkey: { _ in }, usesCarbon: false)
    for i in 1...3 {
        mgr.register(slot: HotkeySlot(
            id: i, keyCode: UInt32(i), modifiers: [.command],
            appPath: "/Applications/Safari.app", label: "App\(i)"
        ))
    }
    mgr.unregisterAll()
    #expect(mgr.registeredSlotIds.isEmpty)
}

@Test func reregisterSameIdReplacesExisting() {
    let mgr = HotkeyManager(onHotkey: { _ in }, usesCarbon: false)
    let slot1 = HotkeySlot(id: 1, keyCode: 0, modifiers: [.command],
                            appPath: "/Applications/Safari.app", label: "Safari")
    let slot2 = HotkeySlot(id: 1, keyCode: 1, modifiers: [.option],
                            appPath: "/Applications/Notes.app", label: "Notes")
    mgr.register(slot: slot1)
    mgr.register(slot: slot2)
    #expect(mgr.registeredSlotIds == Set([1]))
}

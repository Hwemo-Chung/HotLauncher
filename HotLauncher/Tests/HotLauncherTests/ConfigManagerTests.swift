import Testing
import Foundation
@testable import HotLauncher

@Test func loadReturnsDefaultWhenNoFile() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    let config = try mgr.load()
    #expect(config.version == 1)
    #expect(config.slots.isEmpty)
}

@Test func saveAndLoadRoundtrip() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    var config = Config()
    config.slots.append(HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app", label: "Safari"
    ))
    try mgr.save(config)
    let loaded = try mgr.load()
    #expect(loaded.slots.count == 1)
    #expect(loaded.slots[0].label == "Safari")
}

@Test func saveRejectsMoreThanMaxSlots() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    var config = Config()
    config.slots = (1...21).map {
        HotkeySlot(id: $0, keyCode: 0, modifiers: [.command],
                   appPath: "/Applications/Safari.app", label: "A")
    }
    #expect(throws: ConfigError.self) {
        try mgr.save(config)
    }
}

@Test func addSlotEnforcesMax20() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    for i in 1...20 {
        _ = try mgr.addSlot(HotkeySlot(
            id: i, keyCode: UInt32(i), modifiers: [.command],
            appPath: "/Applications/Safari.app", label: "App\(i)"
        ))
    }
    #expect(throws: ConfigError.self) {
        try mgr.addSlot(HotkeySlot(
            id: 21, keyCode: 21, modifiers: [.command],
            appPath: "/Applications/Safari.app", label: "App21"
        ))
    }
}

@Test func removeSlot() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    _ = try mgr.addSlot(HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Safari.app", label: "Safari"
    ))
    let config = try mgr.removeSlot(id: 1)
    #expect(config.slots.isEmpty)
}

@Test func slotLookupById() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    _ = try mgr.addSlot(HotkeySlot(
        id: 5, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Notes.app", label: "Notes"
    ))
    let found = mgr.slot(for: 5)
    #expect(found?.label == "Notes")
    #expect(mgr.slot(for: 99) == nil)
}

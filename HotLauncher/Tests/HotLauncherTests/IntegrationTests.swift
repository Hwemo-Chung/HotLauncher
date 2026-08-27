import Testing
import Foundation
@testable import HotLauncher

@Test func configToLaunchFlow() async throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let configMgr = ConfigManager(directory: dir)
    let mockLauncher = MockAppLauncher()

    _ = try configMgr.addSlot(HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app", label: "Safari"
    ))

    let slot = configMgr.slot(for: 1)
    #expect(slot != nil)
    try await mockLauncher.launch(appPath: slot!.appPath)
    #expect(mockLauncher.launchedPaths == ["/Applications/Safari.app"])
}

@Test func fullConfigLifecycle() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let mgr = ConfigManager(directory: dir)
    _ = try mgr.addSlot(HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Safari.app", label: "Safari"
    ))
    _ = try mgr.addSlot(HotkeySlot(
        id: 2, keyCode: 1, modifiers: [.option],
        appPath: "/Applications/Notes.app", label: "Notes"
    ))
    #expect(try mgr.load().slots.count == 2)

    _ = try mgr.removeSlot(id: 1)
    #expect(try mgr.load().slots.count == 1)
    #expect(mgr.slot(for: 1) == nil)
    #expect(mgr.slot(for: 2)?.label == "Notes")
}

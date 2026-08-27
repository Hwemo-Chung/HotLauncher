import Testing
import Carbon.HIToolbox
@testable import HotLauncher

@Test func slotCodableRoundtrip() throws {
    let slot = HotkeySlot(
        id: 1,
        keyCode: 0,
        modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app",
        label: "Safari"
    )
    let data = try JSONEncoder().encode(slot)
    let decoded = try JSONDecoder().decode(HotkeySlot.self, from: data)
    #expect(decoded == slot)
}

@Test func configCodableRoundtrip() throws {
    let config = Config(version: 1, slots: [
        HotkeySlot(id: 1, keyCode: 0, modifiers: [.command, .shift],
                   appPath: "/Applications/Safari.app", label: "Safari")
    ])
    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(Config.self, from: data)
    #expect(decoded.version == 1)
    #expect(decoded.slots.count == 1)
    #expect(decoded.slots[0] == config.slots[0])
}

@Test func modifierCarbonFlags() {
    #expect(Modifier.command.carbonFlag == UInt32(cmdKey))
    #expect(Modifier.shift.carbonFlag == UInt32(shiftKey))
    #expect(Modifier.option.carbonFlag == UInt32(optionKey))
    #expect(Modifier.control.carbonFlag == UInt32(controlKey))
}

@Test func slotIsArmedRequiresAppAndModifierAndKey() {
    let empty = HotkeySlot(id: 1, keyCode: 0, modifiers: [], appPath: "", label: "")
    #expect(!empty.isArmed)

    let noApp = HotkeySlot(
        id: 1, keyCode: UInt32(kVK_ANSI_A), modifiers: [.command],
        appPath: "", label: "A"
    )
    #expect(!noApp.isArmed)

    let noMod = HotkeySlot(
        id: 1, keyCode: UInt32(kVK_ANSI_A), modifiers: [],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    #expect(!noMod.isArmed)

    let armed = HotkeySlot(
        id: 1, keyCode: UInt32(kVK_ANSI_A), modifiers: [.command],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    #expect(armed.isArmed)
}

@Test func interpretPressCapturesCommandA() {
    let result = interpretHotkeyPress(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: [.command]
    )
    #expect(result == .captured(keyCode: UInt32(kVK_ANSI_A), modifiers: [.command]))
}

@Test func interpretPressCancelsOnEscape() {
    #expect(interpretHotkeyPress(keyCode: UInt32(kVK_Escape), modifiers: []) == .cancel)
}

@Test func interpretPressIgnoresModifierOnlyAndBareKey() {
    #expect(interpretHotkeyPress(keyCode: UInt32(kVK_Command), modifiers: [.command]) == .ignore)
    #expect(interpretHotkeyPress(keyCode: UInt32(kVK_ANSI_A), modifiers: []) == .ignore)
    #expect(interpretHotkeyPress(keyCode: UInt32(kVK_ANSI_A), modifiers: [.shift]) == .ignore)
}

@Test func firstDuplicateArmedPairDetectsClash() {
    let a = HotkeySlot(
        id: 1, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    let b = HotkeySlot(
        id: 2, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Notes.app", label: "Notes"
    )
    let pair = firstDuplicateArmedPair([a, b])
    #expect(pair?.0.id == 1)
    #expect(pair?.1.id == 2)
}

@Test func paddedSlotsFillsTwentyById() {
    let existing = HotkeySlot(
        id: 5, keyCode: 0, modifiers: [.command],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    let padded = paddedSlots([existing])
    #expect(padded.count == 20)
    #expect(padded[0].id == 1)
    #expect(padded[0].appPath.isEmpty)
    #expect(padded[4].label == "Safari")
    #expect(padded[19].id == 20)
}

@Test func shortcutDisplayUsesSymbolsNotUnicodeScalar() {
    let slot = HotkeySlot(
        id: 1, keyCode: UInt32(kVK_ANSI_A), modifiers: [.command, .shift],
        appPath: "/Applications/Safari.app", label: "Safari"
    )
    #expect(slot.shortcutDisplay == "⌘⇧A")
}

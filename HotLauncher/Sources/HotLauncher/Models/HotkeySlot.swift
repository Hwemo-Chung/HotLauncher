import Carbon.HIToolbox

public enum Modifier: String, Codable, Equatable, Sendable {
    case command, option, control, shift

    public var carbonFlag: UInt32 {
        switch self {
        case .command:  return UInt32(cmdKey)
        case .option:   return UInt32(optionKey)
        case .control:  return UInt32(controlKey)
        case .shift:    return UInt32(shiftKey)
        }
    }

    public var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option:  return "⌥"
        case .control: return "⌃"
        case .shift:   return "⇧"
        }
    }
}

public enum HotkeyRecordResult: Equatable, Sendable {
    case captured(keyCode: UInt32, modifiers: [Modifier])
    case cancel
    case ignore
}

private let modifierOnlyKeyCodes: Set<UInt32> = [
    UInt32(kVK_Shift), UInt32(kVK_RightShift),
    UInt32(kVK_Command), UInt32(kVK_RightCommand),
    UInt32(kVK_Option), UInt32(kVK_RightOption),
    UInt32(kVK_Control), UInt32(kVK_RightControl),
    UInt32(kVK_CapsLock), UInt32(kVK_Function),
]

public func interpretHotkeyPress(keyCode: UInt32, modifiers: [Modifier]) -> HotkeyRecordResult {
    if keyCode == UInt32(kVK_Escape) { return .cancel }
    if modifierOnlyKeyCodes.contains(keyCode) { return .ignore }
    let hasPrimary = modifiers.contains { $0 == .command || $0 == .option || $0 == .control }
    guard hasPrimary else { return .ignore }
    return .captured(keyCode: keyCode, modifiers: modifiers)
}

public func carbonKeyLabel(_ keyCode: UInt32) -> String {
    switch Int(keyCode) {
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_M: return "M"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_Z: return "Z"
    case kVK_ANSI_0: return "0"
    case kVK_ANSI_1: return "1"
    case kVK_ANSI_2: return "2"
    case kVK_ANSI_3: return "3"
    case kVK_ANSI_4: return "4"
    case kVK_ANSI_5: return "5"
    case kVK_ANSI_6: return "6"
    case kVK_ANSI_7: return "7"
    case kVK_ANSI_8: return "8"
    case kVK_ANSI_9: return "9"
    case kVK_Space: return "Space"
    case kVK_Return: return "Return"
    case kVK_Tab: return "Tab"
    case kVK_Delete: return "Delete"
    case kVK_ForwardDelete: return "FwdDel"
    case kVK_Escape: return "Esc"
    case kVK_LeftArrow: return "←"
    case kVK_RightArrow: return "→"
    case kVK_UpArrow: return "↑"
    case kVK_DownArrow: return "↓"
    case kVK_F1: return "F1"
    case kVK_F2: return "F2"
    case kVK_F3: return "F3"
    case kVK_F4: return "F4"
    case kVK_F5: return "F5"
    case kVK_F6: return "F6"
    case kVK_F7: return "F7"
    case kVK_F8: return "F8"
    case kVK_F9: return "F9"
    case kVK_F10: return "F10"
    case kVK_F11: return "F11"
    case kVK_F12: return "F12"
    case kVK_ANSI_Minus: return "-"
    case kVK_ANSI_Equal: return "="
    case kVK_ANSI_LeftBracket: return "["
    case kVK_ANSI_RightBracket: return "]"
    case kVK_ANSI_Semicolon: return ";"
    case kVK_ANSI_Quote: return "'"
    case kVK_ANSI_Comma: return ","
    case kVK_ANSI_Period: return "."
    case kVK_ANSI_Slash: return "/"
    case kVK_ANSI_Backslash: return "\\"
    case kVK_ANSI_Grave: return "`"
    default: return "Key\(keyCode)"
    }
}

public struct HotkeySlot: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public var keyCode: UInt32
    public var modifiers: [Modifier]
    public var appPath: String
    public var label: String

    public init(id: Int, keyCode: UInt32, modifiers: [Modifier], appPath: String, label: String) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.appPath = appPath
        self.label = label
    }

    public static func empty(id: Int) -> HotkeySlot {
        HotkeySlot(id: id, keyCode: 0, modifiers: [], appPath: "", label: "")
    }

    public var combinedCarbonModifiers: UInt32 {
        modifiers.reduce(0) { $0 | $1.carbonFlag }
    }

    /// Register only when a real app and a real shortcut exist.
    public var isArmed: Bool {
        !appPath.isEmpty
            && modifiers.contains(where: { $0 != .shift })
            && !modifierOnlyKeyCodes.contains(keyCode)
    }

    public var shortcutDisplay: String {
        if modifiers.isEmpty { return "Click to record" }
        let mods = modifiers.map(\.symbol).joined()
        return mods + carbonKeyLabel(keyCode)
    }
}

public struct Config: Codable, Equatable, Sendable {
    public var version: Int = 1
    public var slots: [HotkeySlot] = []

    public init(version: Int = 1, slots: [HotkeySlot] = []) {
        self.version = version
        self.slots = slots
    }
}

public func paddedSlots(_ slots: [HotkeySlot], count: Int = ConfigManager.maxSlots) -> [HotkeySlot] {
    var byId: [Int: HotkeySlot] = [:]
    for slot in slots where (1...count).contains(slot.id) {
        byId[slot.id] = slot
    }
    return (1...count).map { byId[$0] ?? HotkeySlot.empty(id: $0) }
}

public func firstDuplicateArmedPair(_ slots: [HotkeySlot]) -> (HotkeySlot, HotkeySlot)? {
    var seen: [String: HotkeySlot] = [:]
    for slot in slots where slot.isArmed {
        let key = "\(slot.keyCode):\(slot.combinedCarbonModifiers)"
        if let previous = seen[key] {
            return (previous, slot)
        }
        seen[key] = slot
    }
    return nil
}

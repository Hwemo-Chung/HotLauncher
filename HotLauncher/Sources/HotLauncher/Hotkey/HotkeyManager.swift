import Carbon.HIToolbox
import AppKit

public final class HotkeyManager: HotkeyManagerProtocol {
    private var hotkeys: [Int: EventHotKeyRef] = [:]
    private var registeredIds: Set<Int> = []
    private let onHotkey: (Int) -> Void
    private let usesCarbon: Bool
    private var eventHandler: EventHandlerRef?
    // ponytail: Carbon callback needs a single process-wide target
    nonisolated(unsafe) static var instance: HotkeyManager?

    public var registeredSlotIds: Set<Int> { registeredIds }

    public init(onHotkey: @escaping (Int) -> Void, usesCarbon: Bool = true) {
        self.onHotkey = onHotkey
        self.usesCarbon = usesCarbon
        if usesCarbon {
            Self.instance = self
            installEventHandler()
        }
    }

    @discardableResult
    public func register(slot: HotkeySlot) -> Bool {
        unregister(slotId: slot.id)
        guard usesCarbon else {
            registeredIds.insert(slot.id)
            return true
        }

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x484C4352), // "HLCR"
            id: UInt32(slot.id)
        )
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            slot.keyCode,
            slot.combinedCarbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr, let ref = hotKeyRef else {
            return false
        }
        hotkeys[slot.id] = ref
        registeredIds.insert(slot.id)
        return true
    }

    public func unregister(slotId: Int) {
        registeredIds.remove(slotId)
        if let ref = hotkeys.removeValue(forKey: slotId) {
            UnregisterEventHotKey(ref)
        }
    }

    public func unregisterAll() {
        for (_, ref) in hotkeys {
            UnregisterEventHotKey(ref)
        }
        hotkeys.removeAll()
        registeredIds.removeAll()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        var handler: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if status == noErr {
                    HotkeyManager.instance?.onHotkey(Int(hotKeyID.id))
                }
                return noErr
            },
            1, &eventType, nil, &handler
        )
        eventHandler = handler
    }

    deinit {
        unregisterAll()
        if usesCarbon {
            if let eventHandler {
                RemoveEventHandler(eventHandler)
            }
            if Self.instance === self {
                Self.instance = nil
            }
        }
    }
}

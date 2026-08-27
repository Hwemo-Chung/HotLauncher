public protocol HotkeyManagerProtocol {
    @discardableResult
    func register(slot: HotkeySlot) -> Bool
    func unregister(slotId: Int)
    func unregisterAll()
    var registeredSlotIds: Set<Int> { get }
}

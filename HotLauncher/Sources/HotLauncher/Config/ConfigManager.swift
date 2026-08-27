import Foundation

public enum ConfigError: Error, Equatable {
    case maxSlotsReached
}

public final class ConfigManager: @unchecked Sendable {
    public static let maxSlots = 20
    private let configURL: URL
    private let lock = NSLock()

    public init(directory: URL) {
        self.configURL = directory.appendingPathComponent("config.json")
    }

    public convenience init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("HotLauncher")
        try? FileManager.default.createDirectory(
            at: appSupport, withIntermediateDirectories: true
        )
        self.init(directory: appSupport)
    }

    public func load() throws -> Config {
        lock.lock()
        defer { lock.unlock() }
        return try loadUnlocked()
    }

    public func save(_ config: Config) throws {
        lock.lock()
        defer { lock.unlock() }
        guard config.slots.count <= Self.maxSlots else {
            throw ConfigError.maxSlotsReached
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    @discardableResult
    public func addSlot(_ slot: HotkeySlot) throws -> Config {
        lock.lock()
        defer { lock.unlock() }
        var config = try loadUnlocked()
        guard config.slots.count < Self.maxSlots else {
            throw ConfigError.maxSlotsReached
        }
        config.slots.removeAll { $0.id == slot.id }
        config.slots.append(slot)
        try saveUnlocked(config)
        return config
    }

    @discardableResult
    public func removeSlot(id: Int) throws -> Config {
        lock.lock()
        defer { lock.unlock() }
        var config = try loadUnlocked()
        config.slots.removeAll { $0.id == id }
        try saveUnlocked(config)
        return config
    }

    public func slot(for id: Int) -> HotkeySlot? {
        (try? load())?.slots.first { $0.id == id }
    }

    private func loadUnlocked() throws -> Config {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return Config()
        }
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(Config.self, from: data)
    }

    private func saveUnlocked(_ config: Config) throws {
        guard config.slots.count <= Self.maxSlots else {
            throw ConfigError.maxSlotsReached
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }
}

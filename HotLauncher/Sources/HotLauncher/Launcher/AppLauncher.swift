import AppKit

public enum LaunchError: Error, Equatable {
    case appNotFound(String)
    case notAnApplication(String)
}

public final class AppLauncher: AppLauncherProtocol {
    public init() {}

    public func appExists(at path: String) -> Bool {
        isApplicationBundle(at: path)
    }

    public func launch(appPath: String) async throws {
        let path = URL(fileURLWithPath: appPath).standardizedFileURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw LaunchError.appNotFound(appPath)
        }
        guard isApplicationBundle(at: path) else {
            throw LaunchError.notAnApplication(appPath)
        }
        let url = URL(fileURLWithPath: path)
        let config = NSWorkspace.OpenConfiguration()
        try await NSWorkspace.shared.openApplication(at: url, configuration: config)
    }

    private func isApplicationBundle(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard url.pathExtension.lowercased() == "app" else { return false }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        let info = url.appendingPathComponent("Contents/Info.plist")
        return FileManager.default.fileExists(atPath: info.path)
    }
}

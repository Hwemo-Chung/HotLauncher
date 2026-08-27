@testable import HotLauncher

final class MockAppLauncher: AppLauncherProtocol, @unchecked Sendable {
    var launchedPaths: [String] = []

    func appExists(at path: String) -> Bool { true }

    func launch(appPath: String) async throws {
        launchedPaths.append(appPath)
    }
}

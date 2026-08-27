public protocol AppLauncherProtocol: Sendable {
    func launch(appPath: String) async throws
    func appExists(at path: String) -> Bool
}

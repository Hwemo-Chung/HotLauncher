import Testing
import Foundation
@testable import HotLauncher

@Test func launchRejectsNonexistentApp() async {
    let launcher = AppLauncher()
    await #expect(throws: LaunchError.self) {
        try await launcher.launch(appPath: "/Applications/NonExistent12345.app")
    }
}

@Test func appExistsCheckForRealApp() {
    let launcher = AppLauncher()
    // Check common macOS app locations
    let exists = launcher.appExists(at: "/System/Applications/Calculator.app")
        || launcher.appExists(at: "/Applications/Calculator.app")
        || launcher.appExists(at: "/System/Applications/TextEdit.app")
    #expect(exists)
}

@Test func appExistsCheckForFakeApp() {
    let launcher = AppLauncher()
    #expect(!launcher.appExists(at: "/Applications/FakeApp12345.app"))
}

@Test func appExistsRejectsPlainDirectory() {
    let launcher = AppLauncher()
    #expect(!launcher.appExists(at: "/tmp"))
}

@Test func launchRejectsPlainDirectory() async {
    let launcher = AppLauncher()
    await #expect(throws: LaunchError.self) {
        try await launcher.launch(appPath: "/tmp")
    }
}

@Test func mockLauncherRecordsCalls() async throws {
    let mock = MockAppLauncher()
    try await mock.launch(appPath: "/Applications/Safari.app")
    #expect(mock.launchedPaths == ["/Applications/Safari.app"])
}

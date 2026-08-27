import Testing
import ServiceManagement
@testable import HotLauncher

@Test func loginLaunchEnabledOnlyWhenStatusEnabled() {
    #expect(LoginLaunch.isEnabled(status: .enabled))
    #expect(!LoginLaunch.isEnabled(status: .notRegistered))
    #expect(!LoginLaunch.isEnabled(status: .notFound))
    #expect(!LoginLaunch.isEnabled(status: .requiresApproval))
}

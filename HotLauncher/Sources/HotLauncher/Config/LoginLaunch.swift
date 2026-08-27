import ServiceManagement

public enum LoginLaunch {
    public static var isEnabled: Bool {
        isEnabled(status: SMAppService.mainApp.status)
    }

    public static func isEnabled(status: SMAppService.Status) -> Bool {
        status == .enabled
    }

    public static func setEnabled(_ on: Bool) throws {
        let app = SMAppService.mainApp
        if on {
            if app.status == .enabled { return }
            try app.register()
            if app.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } else if app.status != .notRegistered {
            try app.unregister()
        }
    }
}

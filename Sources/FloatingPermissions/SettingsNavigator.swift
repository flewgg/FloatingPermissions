import AppKit

@MainActor
final class SettingsNavigator {
    /// Opens System Settings with a generic deeplink URL.
    @discardableResult
    func openSettings(at url: URL) -> Bool {
        NSWorkspace.shared.openApplication(
            at: SystemSettingsIdentifiers.applicationURL,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }

        let didOpen = NSWorkspace.shared.open(url)
        activateSettings()
        return didOpen
    }

    /// Re-activates the running System Settings process if it already exists.
    func activateSettings() {
        NSRunningApplication.runningApplications(withBundleIdentifier: SystemSettingsIdentifiers.bundleIdentifier)
            .first?
            .activate()
    }
}

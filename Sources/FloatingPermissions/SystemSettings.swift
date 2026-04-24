import Foundation

public enum SystemSettings {
    /// Opens a System Settings page from a pane identifier and optional anchor.
    @MainActor
    @discardableResult
    public static func open(
        paneIdentifier: String,
        anchor: String? = nil
    ) -> Bool {
        open(SystemSettingsDestination(paneIdentifier: paneIdentifier, anchor: anchor))
    }

    /// Opens a System Settings page from a prebuilt deeplink destination.
    @MainActor
    @discardableResult
    public static func open(_ destination: SystemSettingsDestination) -> Bool {
        SettingsNavigator().openSettings(at: destination.url)
    }

    /// Opens System Settings from a fully built deeplink URL.
    @MainActor
    @discardableResult
    public static func open(url: URL) -> Bool {
        SettingsNavigator().openSettings(at: url)
    }

    /// Re-activates the running System Settings app if it already exists.
    @MainActor
    public static func activate() {
        SettingsNavigator().activateSettings()
    }
}

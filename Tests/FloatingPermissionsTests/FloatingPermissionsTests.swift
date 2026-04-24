import Foundation
import Testing
@testable import FloatingPermissions

@Test func moduleNameIsStable() {
    #expect(String(describing: FloatingPermissions.self) == "FloatingPermissions")
}

@Test
func paneURLsUseSecuritySettingsDeepLink() {
    #expect(
        FloatingPermissionPane.fullDiskAccess.settingsURL.absoluteString ==
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
    )
}

@Test
func typedDisplaysAnchorBuildsDeepLink() {
    #expect(
        SystemSettingsDestination.displays(anchor: .resolutionSection).url.absoluteString ==
        "x-apple.systempreferences:com.apple.Displays-Settings.extension?resolutionSection"
    )
}

@Test
@MainActor
func controllerAcceptsOnlyUniqueAppBundles() {
    let controller = FloatingPermissionsController()
    let appURL = URL(fileURLWithPath: "/Applications/Test.app")

    controller.registerDroppedApp(appURL)
    controller.registerDroppedApp(appURL)
    controller.registerDroppedApp(URL(fileURLWithPath: "/tmp/not-an-app.txt"))

    #expect(controller.droppedApps == [appURL])
}

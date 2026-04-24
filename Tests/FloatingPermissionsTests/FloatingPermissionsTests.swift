import Foundation
import Testing
@testable import FloatingPermissions

@Test func moduleNameIsStable() {
    #expect(String(describing: FloatingPermissions.self) == "FloatingPermissions")
}

@Test
func paneURLsUseSecuritySettingsDeepLinks() {
    #expect(
        FloatingPermissionPane.accessibility.settingsURL.absoluteString ==
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
    )
    #expect(
        FloatingPermissionPane.inputMonitoring.settingsURL.absoluteString ==
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent"
    )
}

@Test
func supportedPanesStayFocused() {
    #expect(FloatingPermissionPane.allCases == [.accessibility, .inputMonitoring])
}

@Test
func permissionStatusHelpersAreReachable() {
    let grantedStates = FloatingPermissionPane.allCases.map(\.isGranted)

    #expect(grantedStates.count == FloatingPermissionPane.allCases.count)
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

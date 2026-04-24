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
    let authorizationStates = FloatingPermissionPane.allCases.map(\.authorizationState)
    let grantedStates = FloatingPermissionPane.allCases.map(\.isGranted)

    #expect(authorizationStates.count == FloatingPermissionPane.allCases.count)
    #expect(grantedStates.count == FloatingPermissionPane.allCases.count)
}

@Test
func statusProvidersMatchSupportedPanes() {
    for pane in FloatingPermissionPane.allCases {
        let provider = PermissionStatusRegistry.provider(for: pane)

        #expect(provider.capability == .preflightSupported)
        #expect([.granted, .notGranted].contains(provider.authorizationState()))
    }
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

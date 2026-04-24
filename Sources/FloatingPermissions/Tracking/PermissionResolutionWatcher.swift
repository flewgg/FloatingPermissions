import AppKit
import CoreGraphics
import Foundation

@MainActor
enum PermissionResolutionWatcher {
    static func waitForResolution(
        pane: FloatingPermissionPane,
        timeout: Duration
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        var peakSettingsWindowCount = countSettingsWindows()
        var hostLostFocus = false

        while clock.now < deadline {
            if pane.isGranted {
                return true
            }

            let settingsWindowCount = countSettingsWindows()
            if settingsWindowCount > peakSettingsWindowCount {
                peakSettingsWindowCount = settingsWindowCount
            } else if settingsWindowCount < peakSettingsWindowCount {
                return await finalGrantCheck(for: pane)
            }

            if NSApp.isActive == false {
                hostLostFocus = true
            } else if hostLostFocus {
                return await finalGrantCheck(for: pane)
            }

            try? await Task.sleep(for: .milliseconds(120))
        }

        return pane.isGranted
    }

    private static func finalGrantCheck(for pane: FloatingPermissionPane) async -> Bool {
        try? await Task.sleep(for: .milliseconds(200))
        return pane.isGranted
    }

    private static func countSettingsWindows() -> Int {
        let settingsOwners: Set<String> = ["System Settings", "System Preferences"]
        guard
            let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return 0
        }

        return windows.reduce(into: 0) { total, window in
            guard let ownerName = window[kCGWindowOwnerName as String] as? String else { return }
            if settingsOwners.contains(ownerName) {
                total += 1
            }
        }
    }
}

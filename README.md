# FloatingPermissions

FloatingPermissions is a macOS Swift package for guiding users through drag-based privacy permissions in System Settings.

It opens the target Privacy & Security pane, waits for the System Settings window to appear, and shows a floating helper panel that follows the Settings window. The helper lets the user drag the current app bundle into the permission list.

## Requirements

- macOS 14 or later
- Swift 6
- Swift Package Manager

## Installation

Add the package in Xcode:

1. Choose **File > Add Package Dependencies...**
2. Enter:

   ```text
   https://github.com/flewgg/FloatingPermissions.git
   ```

3. Use version `0.1.1` or newer.
4. Add the `FloatingPermissions` product to your app target.

Or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/flewgg/FloatingPermissions.git", from: "0.1.1")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "FloatingPermissions", package: "FloatingPermissions")
    ]
)
```

## Supported Permissions

FloatingPermissions currently supports the two drag-based privacy panes used by our apps:

- Accessibility
- Input Monitoring

The package keeps the permission model intentionally small and modular so more panes can be added later.

## SwiftUI Usage

Use `FloatingPermissionsButton` when you want a ready-made button:

```swift
import FloatingPermissions
import SwiftUI

struct PermissionsView: View {
    var body: some View {
        FloatingPermissionsButton(
            title: "Open Accessibility",
            pane: .accessibility,
            suggestedAppURLs: [Bundle.main.bundleURL]
        )
    }
}
```

For Input Monitoring:

```swift
FloatingPermissionsButton(
    title: "Open Input Monitoring",
    pane: .inputMonitoring,
    suggestedAppURLs: [Bundle.main.bundleURL]
)
```

## Controller Usage

Use `FloatingPermissionsController` directly when your own UI should trigger the flow:

```swift
import FloatingPermissions
import SwiftUI

@MainActor
final class PermissionModel: ObservableObject {
    private let controller = FloatingPermissionsController()

    func openAccessibility() {
        controller.authorize(
            pane: .accessibility,
            suggestedAppURLs: [Bundle.main.bundleURL]
        )
    }
}
```

You can pass a source frame in screen coordinates if you want the helper to animate from the triggering control:

```swift
controller.authorize(
    pane: .accessibility,
    suggestedAppURLs: [Bundle.main.bundleURL],
    sourceFrameInScreen: sourceFrame
)
```

## Configuration

`FloatingPermissionsConfiguration` lets you provide default app bundle URLs and optionally prompt for Accessibility trust so window tracking can use Accessibility notifications immediately:

```swift
let configuration = FloatingPermissionsConfiguration(
    requiredAppURLs: [Bundle.main.bundleURL],
    promptForAccessibilityTrust: false
)

let controller = FloatingPermissionsController(configuration: configuration)
```

Window-server tracking works without prompting. Accessibility trust only improves live window move/resize tracking.

## Permission Status

Check the current permission state for the calling app:

```swift
let accessibilityGranted = FloatingPermissionPane.accessibility.isGranted
let inputMonitoringGranted = FloatingPermissionPane.inputMonitoring.isGranted
```

Use the authorization state when you need more than a boolean:

```swift
let accessibilityState = FloatingPermissionPane.accessibility.authorizationState
```

These checks mirror the guided flow: Accessibility uses `AXIsProcessTrusted()` and Input Monitoring uses `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)`.

## Behavior

- Opens System Settings with the correct privacy deeplink.
- Shows the floating helper only after the System Settings window appears and its frame stabilizes.
- Keeps one active floating helper at a time.
- Docks a compact material helper inside the System Settings window.
- Animates the helper from the triggering control toward the Settings window.
- Tracks the System Settings window and keeps the helper visually attached to it.
- Makes the helper mouse-transparent while dragging so System Settings can receive the drop.
- Hides the helper while the TCC prompt resolves, then closes it when permission is granted.
- Does not force focus back to the app after the helper closes.
- Uses the compact app row as the drag preview.

## Example App

The `Example` folder contains a small macOS app with buttons for the supported permission panes.

Open `Example/Example.xcodeproj` in Xcode and run the `Example` scheme.

## Tests

Run the package tests with:

```sh
swift test
```

The tests cover supported panes, deeplink construction, module identity, and app URL de-duplication.

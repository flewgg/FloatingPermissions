# FloatingPermissions

FloatingPermissions is a macOS Swift package for guiding users through the
drag-based Privacy & Security permission panes in System Settings.

It opens the requested pane, waits until the System Settings window is visible,
and shows a small floating guide panel with the app bundle ready to drag into
the permission list. The package also exposes permission status helpers so apps
can decide whether the guide is needed before showing it.

## Features

- SwiftUI button for the common "open permission guide" flow.
- Controller API for custom onboarding and settings screens.
- Floating helper panel that follows the System Settings window.
- App bundle drag item that becomes mouse-transparent while dragging so System Settings receives the drop.
- Permission status helpers for Accessibility and Input Monitoring.
- One active guide panel at a time.
- macOS 14+ only, with no older-platform compatibility code.

## Requirements

- macOS 14.0 or later
- Swift 6.3-compatible toolchain

FloatingPermissions is macOS-only. It cannot grant permissions silently; users
still approve permissions through Apple's System Settings UI.

## Installation

### Xcode

1. Choose **File > Add Package Dependencies...**
2. Enter the repository URL:

   ```text
   https://github.com/flewgg/FloatingPermissions.git
   ```

3. Select the latest release.
4. Add the `FloatingPermissions` product to your app target.

### Package.swift

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

FloatingPermissions currently supports:

- Accessibility
- Input Monitoring

The permission model is intentionally small and modular so the package can add
more panes later without changing the guide lifecycle.

## Quick Start

Use `FloatingPermissionsButton` when you want a ready-made SwiftUI control:

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

## Status Checks

Check whether the calling app already has permission:

```swift
let canUseAccessibility = FloatingPermissionPane.accessibility.isGranted
let canListenForInput = FloatingPermissionPane.inputMonitoring.isGranted
```

For more detail, read the authorization state:

```swift
switch FloatingPermissionPane.accessibility.authorizationState {
case .granted:
    startFeature()
case .notGranted:
    showPermissionGuide()
case .unknown, .checking:
    showFallbackState()
}
```

The built-in providers use:

- Accessibility: `AXIsProcessTrusted()`
- Input Monitoring: `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)`

## Custom UI

Use `FloatingPermissionsController` directly when your app has its own button,
row, onboarding step, or settings screen.

```swift
import FloatingPermissions
import SwiftUI

@MainActor
final class PermissionModel: ObservableObject {
    private let controller = FloatingPermissions.makeController(
        configuration: FloatingPermissionsConfiguration(
            requiredAppURLs: [Bundle.main.bundleURL]
        )
    )

    func openAccessibility() {
        controller.authorize(pane: .accessibility)
    }
}
```

If you know the triggering control's frame in screen coordinates, pass it to
animate the helper from that control toward System Settings:

```swift
controller.authorize(
    pane: .accessibility,
    suggestedAppURLs: [Bundle.main.bundleURL],
    sourceFrameInScreen: sourceFrame
)
```

## Configuration

`FloatingPermissionsConfiguration` lets you provide default app bundle URLs and
control whether the package prompts for Accessibility trust to improve window
tracking.

```swift
let configuration = FloatingPermissionsConfiguration(
    requiredAppURLs: [Bundle.main.bundleURL],
    promptForAccessibilityTrust: false
)

let controller = FloatingPermissionsController(configuration: configuration)
```

Window-server tracking works without prompting. Accessibility trust only improves
live System Settings window move and resize tracking.

## Custom Status Providers

The default status providers are registered automatically. Apps can replace a
provider when they need app-specific behavior:

```swift
import ApplicationServices
import FloatingPermissions

struct MyAccessibilityStatusProvider: PermissionStatusProviding {
    var capability: PermissionStatusCapability { .preflightSupported }

    func authorizationState() -> PermissionAuthorizationState {
        AXIsProcessTrusted() ? .granted : .notGranted
    }
}

PermissionStatusRegistry.register(
    provider: MyAccessibilityStatusProvider(),
    for: .accessibility
)
```

## Guide Panel Behavior

- Opens the matching Privacy & Security page in System Settings.
- Shows the floating helper only after the System Settings window appears and its frame stabilizes.
- Docks the helper inside the Settings window's content area.
- Uses a material background and compact app drag row.
- Provides a close button that returns focus to the previously frontmost app.
- Provides a gear button when System Settings is not frontmost, so the user can bring Settings back.
- Hides the helper while macOS resolves the permission prompt.
- Closes automatically after the permission status check reports granted.

## Example App

The `Example` folder contains a small macOS app with buttons for the supported
permission panes.

Open `Example/Example.xcodeproj` in Xcode and run the `Example` scheme.

## Tests

Run the package tests with:

```sh
swift test
```

The tests cover supported panes, System Settings deeplinks, module identity,
permission status providers, and app URL de-duplication.

## Limitations

- System Settings is owned by macOS. Apple can change its UI, timing, or drag behavior between releases.
- FloatingPermissions cannot add an app to a permission list without the user's drag/drop action.
- The guide text is currently English-only. Apps that need localized copy should build their own UI around `FloatingPermissionsController`.
- Permission status checks report the current process. Test from a real `.app` bundle when validating TCC behavior.

## License

FloatingPermissions is available under the MIT License. See `LICENSE`.

Some guide-panel and permission-resolution behavior is adapted from other MIT
licensed projects. See `THIRD_PARTY_NOTICES.md` for details.

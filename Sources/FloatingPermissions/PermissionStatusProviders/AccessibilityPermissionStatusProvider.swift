import ApplicationServices

public struct AccessibilityPermissionStatusProvider: PermissionStatusProviding {
    public var capability: PermissionStatusCapability { .preflightSupported }

    public init() {}

    public func authorizationState() -> PermissionAuthorizationState {
        AXIsProcessTrusted() ? .granted : .notGranted
    }
}

import IOKit.hid

public struct InputMonitoringPermissionStatusProvider: PermissionStatusProviding {
    public var capability: PermissionStatusCapability { .preflightSupported }

    public init() {}

    public func authorizationState() -> PermissionAuthorizationState {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted ? .granted : .notGranted
    }
}

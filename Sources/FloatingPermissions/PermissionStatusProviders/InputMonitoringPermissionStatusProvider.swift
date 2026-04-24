import Carbon

public struct InputMonitoringPermissionStatusProvider: PermissionStatusProviding {
    public var capability: PermissionStatusCapability { .preflightSupported }

    public init() {}

    public func authorizationState() -> PermissionAuthorizationState {
        CGPreflightListenEventAccess() ? .granted : .notGranted
    }
}

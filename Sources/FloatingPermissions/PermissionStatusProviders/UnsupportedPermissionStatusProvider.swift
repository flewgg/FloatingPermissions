public struct UnsupportedPermissionStatusProvider: PermissionStatusProviding {
    public var capability: PermissionStatusCapability { .unsupported }

    public init() {}

    public func authorizationState() -> PermissionAuthorizationState {
        .unknown
    }
}

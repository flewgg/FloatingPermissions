public protocol PermissionStatusProviding: Sendable {
    /// Describes whether this provider can reliably check permission status.
    var capability: PermissionStatusCapability { get }

    /// Returns the current authorization state for this permission.
    func authorizationState() -> PermissionAuthorizationState
}

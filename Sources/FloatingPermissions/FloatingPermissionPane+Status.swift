public extension FloatingPermissionPane {
    /// Current authorization state for the calling process.
    var authorizationState: PermissionAuthorizationState {
        PermissionStatusRegistry.provider(for: self).authorizationState()
    }

    /// Status-checking capability for this permission pane.
    var statusCapability: PermissionStatusCapability {
        PermissionStatusRegistry.provider(for: self).capability
    }

    /// Current permission state for the calling process.
    var isGranted: Bool {
        authorizationState == .granted
    }
}

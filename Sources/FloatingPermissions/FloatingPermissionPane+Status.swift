import ApplicationServices

public extension FloatingPermissionPane {
    /// Current permission state for the calling process.
    var isGranted: Bool {
        switch self {
        case .accessibility:
            AXIsProcessTrusted()
        case .inputMonitoring:
            CGPreflightListenEventAccess()
        }
    }
}

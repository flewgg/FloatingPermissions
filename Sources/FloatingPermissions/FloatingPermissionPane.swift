import Foundation

public enum FloatingPermissionPane: String, CaseIterable, Codable, Sendable {
    /// Accessibility permissions list.
    case accessibility
    /// Input Monitoring permissions list.
    case inputMonitoring

    /// The matching typed Privacy & Security anchor in FloatingPermissions.
    public var privacyAnchor: PrivacySecurityAnchor {
        switch self {
        case .accessibility: .privacyAccessibility
        case .inputMonitoring: .privacyListenEvent
        }
    }

    /// Deep link to the corresponding page inside System Settings.
    public var settingsURL: URL {
        SystemSettingsDestination.privacy(anchor: privacyAnchor).url
    }

    /// Human-readable title for the permission pane.
    public var displayTitle: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .inputMonitoring:
            return "Input Monitoring"
        }
    }
}

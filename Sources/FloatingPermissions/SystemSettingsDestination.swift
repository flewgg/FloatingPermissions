import Foundation

/// Anchor points for navigating to specific sections within the Privacy & Security settings pane.
/// Only currently supported floating permission panes are modelled here.
public enum PrivacySecurityAnchor: String, CaseIterable, Sendable {
    /// Opens Accessibility privacy permissions.
    case privacyAccessibility = "Privacy_Accessibility"
    /// Opens input and event monitoring permissions.
    case privacyListenEvent = "Privacy_ListenEvent"
}

public struct SystemSettingsDestination: Hashable, Sendable {
    public let url: URL

    /// The pane or extension identifier used by System Settings when the
    /// destination is backed by a macOS deeplink.
    public let paneIdentifier: String?

    /// Optional anchor for a subsection inside a macOS pane.
    public let anchor: String?

    public init(url: URL, paneIdentifier: String? = nil, anchor: String? = nil) {
        self.url = url
        self.paneIdentifier = paneIdentifier
        self.anchor = anchor
    }
}

public extension SystemSettingsDestination {
    init(paneIdentifier: String, anchor: String? = nil) {
        let encodedAnchor = anchor?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let value = if let encodedAnchor, encodedAnchor.isEmpty == false {
            "x-apple.systempreferences:\(paneIdentifier)?\(encodedAnchor)"
        } else {
            "x-apple.systempreferences:\(paneIdentifier)"
        }

        self.init(
            url: URL(string: value)!,
            paneIdentifier: paneIdentifier,
            anchor: anchor
        )
    }
}

public extension SystemSettingsDestination {
    /// Privacy & Security home page.
    static func privacy() -> Self {
        Self(paneIdentifier: "com.apple.settings.PrivacySecurity.extension")
    }

    /// Convenience helper for the Privacy & Security extension anchors.
    static func privacy(anchor: String) -> Self {
        Self(
            paneIdentifier: "com.apple.settings.PrivacySecurity.extension",
            anchor: anchor
        )
    }

    /// Convenience helper for typed Privacy & Security anchors.
    static func privacy(anchor: PrivacySecurityAnchor) -> Self {
        Self(
            paneIdentifier: "com.apple.settings.PrivacySecurity.extension",
            anchor: anchor.rawValue
        )
    }
}

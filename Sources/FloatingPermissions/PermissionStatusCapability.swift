import Foundation

public enum PermissionStatusCapability: String, CaseIterable, Codable, Sendable {
    /// Permission status can be reliably determined before opening System Settings.
    case preflightSupported
    /// Permission status cannot be reliably determined programmatically.
    case unsupported
}

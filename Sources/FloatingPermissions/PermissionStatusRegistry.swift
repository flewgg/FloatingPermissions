import Foundation

public enum PermissionStatusRegistry {
    private static let storage = PermissionStatusStorage()

    /// Registers or replaces a provider for a specific permission pane.
    public static func register(
        provider: any PermissionStatusProviding,
        for pane: FloatingPermissionPane
    ) {
        storage.register(provider: provider, for: pane)
    }

    /// Registers multiple providers in one call.
    public static func register(
        providers: [FloatingPermissionPane: any PermissionStatusProviding]
    ) {
        storage.register(providers: providers)
    }

    /// Returns the appropriate status provider for the given permission pane.
    public static func provider(for pane: FloatingPermissionPane) -> any PermissionStatusProviding {
        storage.provider(for: pane)
    }
}

private final class PermissionStatusStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var registeredProviders: [FloatingPermissionPane: any PermissionStatusProviding] = [
        .accessibility: AccessibilityPermissionStatusProvider(),
        .inputMonitoring: InputMonitoringPermissionStatusProvider(),
    ]

    func register(
        provider: any PermissionStatusProviding,
        for pane: FloatingPermissionPane
    ) {
        lock.lock()
        defer { lock.unlock() }
        registeredProviders[pane] = provider
    }

    func register(providers: [FloatingPermissionPane: any PermissionStatusProviding]) {
        lock.lock()
        defer { lock.unlock() }
        for (pane, provider) in providers {
            registeredProviders[pane] = provider
        }
    }

    func provider(for pane: FloatingPermissionPane) -> any PermissionStatusProviding {
        lock.lock()
        defer { lock.unlock() }
        return registeredProviders[pane] ?? UnsupportedPermissionStatusProvider()
    }
}

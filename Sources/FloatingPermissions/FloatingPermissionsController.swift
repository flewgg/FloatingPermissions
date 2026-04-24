import AppKit
import Combine
import SwiftUI

@MainActor
public final class FloatingPermissionsController: ObservableObject {
    /// The package exposes a single active floating panel at a time so opening
    /// a second floating permission flow closes the previous panel automatically.
    private static var activeController: FloatingPermissionsController?
    private let systemSettingsBundleIdentifier = "com.apple.systempreferences"

    /// Apps currently represented in the floating panel.
    @Published public private(set) var droppedApps: [URL]

    /// The permission pane currently being guided.
    @Published public private(set) var currentPane: FloatingPermissionPane?

    /// Drives the visibility of the "reopen settings" action.
    @Published var isSettingsFrontmost = false

    public var onDrop: ((URL) -> Void)?

    private let configuration: FloatingPermissionsConfiguration
    private let tracker = SettingsWindowTracker()

    private var panel: FloatingDropPanel?
    private var pendingLaunchSourceFrame: CGRect?
    private var permissionPollTimer: Timer?
    private var permissionResolutionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    public init(configuration: FloatingPermissionsConfiguration = .init()) {
        self.configuration = configuration
        self.droppedApps = configuration.requiredAppURLs.uniqueAppURLs()

        updateFrontmostAppState()
        bindTrackerCallbacks()
        observeFrontmostApplication()
    }

    /// Opens the requested privacy pane and starts the floating guidance flow.
    ///
    /// - Parameters:
    ///   - pane: The permission pane to open inside System Settings.
    ///   - suggestedAppURLs: Optional `.app` bundle URLs that should appear in
    ///     the floating panel as drag candidates. This parameter defaults to an
    ///     empty array, which means no explicit app list is injected here.
    ///     When this value is empty and no previously registered app is
    ///     available, the floating panel falls back to `Bundle.main.bundleURL`
    ///     if the current host bundle is itself an `.app`.
    ///   - sourceFrameInScreen: Optional source rect in screen coordinates used
    ///     as the launch point for the fly-to-settings animation. If omitted,
    ///     the panel still appears, but it skips the source-origin animation.
    public func authorize(
        pane: FloatingPermissionPane,
        suggestedAppURLs: [URL] = [],
        sourceFrameInScreen: CGRect? = nil
    ) {
        closeOtherActivePanelIfNeeded()

        currentPane = pane
        pendingLaunchSourceFrame = sourceFrameInScreen
        mergeDroppedApps(with: suggestedAppURLs)
        SystemSettings.open(url: pane.settingsURL)

        Self.activeController = self
        startPermissionPolling()
        tracker.startTracking(promptIfNeeded: configuration.promptForAccessibilityTrust)
    }

    /// Shows the panel immediately. If the target System Settings frame is
    /// already known, the panel is positioned or animated into place at once.
    public func showPanel() {
        if panel == nil {
            panel = FloatingDropPanel(controller: self)
        }

        guard let panel else { return }

        if let settingsFrame = tracker.currentFrame {
            presentPanel(panel, for: settingsFrame)
            return
        }

        if let sourceFrame = pendingLaunchSourceFrame {
            panel.show(at: sourceFrame)
        } else {
            panel.center()
            panel.show()
        }
    }

    public func closePanel() {
        permissionResolutionTask?.cancel()
        permissionResolutionTask = nil
        stopPermissionPolling()
        tracker.stopTracking()
        panel?.close()
        panel = nil
        pendingLaunchSourceFrame = nil

        if Self.activeController === self {
            Self.activeController = nil
        }
    }

    public func resetDroppedApps() {
        droppedApps = configuration.requiredAppURLs.uniqueAppURLs()
    }

    /// Registers a unique `.app` bundle URL and notifies the host if needed.
    public func registerDroppedApp(_ url: URL) {
        guard url.pathExtension.lowercased() == "app" else { return }
        let normalizedURL = url.standardizedFileURL
        guard droppedApps.contains(normalizedURL) == false else { return }
        droppedApps.append(normalizedURL)
        onDrop?(normalizedURL)
    }

    /// The panel always renders a single primary app card. If the host has not
    /// supplied one yet, the host application's bundle becomes the fallback.
    var preferredAppURL: URL? {
        if let first = droppedApps.first {
            return first
        }
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL
        return bundleURL.pathExtension.lowercased() == "app" ? bundleURL : nil
    }

    /// The panel becomes mouse-transparent while dragging so System Settings
    /// underneath can receive the drop.
    func setPanelDragging(
        _ isDragging: Bool,
        completedOperation: NSDragOperation? = nil
    ) {
        panel?.setDraggingPassthrough(isDragging)

        if isDragging == false, let completedOperation, completedOperation.isEmpty == false {
            waitForPermissionResolutionAfterDrop()
        }
    }

    /// Keeps System Settings visually present whenever the floating panel is
    /// clicked or momentarily considered for focus.
    func keepSettingsVisible() {
        SystemSettings.activate()
        panel?.orderFrontRegardless()
    }

    func reopenCurrentSettingsPane() {
        guard let currentPane else { return }
        SystemSettings.open(url: currentPane.settingsURL)
        panel?.orderFrontRegardless()
    }

    /// Merges unique app bundle URLs into the current panel list.
    func mergeDroppedApps(with urls: [URL]) {
        for url in urls.uniqueAppURLs() {
            registerDroppedApp(url)
        }
    }

    private func bindTrackerCallbacks() {
        tracker.onFrameChange = { [weak self] frame in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.showPanel(for: frame)
            }
        }
        tracker.onTrackingEnded = { [weak self] in
            Task { @MainActor [weak self] in
                self?.closePanel()
            }
        }
    }

    private func observeFrontmostApplication() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrontmostAppState()
                self?.closePanelIfPermissionGranted()
            }
            .store(in: &cancellables)
    }

    private func closeOtherActivePanelIfNeeded() {
        if let activeController = Self.activeController, activeController !== self {
            activeController.closePanel()
        }
    }

    private func presentPanel(_ panel: FloatingDropPanel?, for settingsFrame: CGRect) {
        guard let panel else { return }
        guard closePanelIfPermissionGranted() == false else { return }

        if let sourceFrame = pendingLaunchSourceFrame {
            panel.present(from: sourceFrame, to: settingsFrame)
            pendingLaunchSourceFrame = nil
        } else {
            panel.snap(to: settingsFrame)
        }
    }

    private func showPanel(for settingsFrame: CGRect) {
        if panel == nil {
            panel = FloatingDropPanel(controller: self)
        }

        presentPanel(panel, for: settingsFrame)
    }

    private func updateFrontmostAppState() {
        isSettingsFrontmost =
            NSWorkspace.shared.frontmostApplication?.bundleIdentifier == systemSettingsBundleIdentifier
    }

    private func startPermissionPolling() {
        stopPermissionPolling()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePanelIfPermissionGranted()
            }
        }
        permissionPollTimer?.tolerance = 0.2
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    @discardableResult
    private func closePanelIfPermissionGranted() -> Bool {
        guard let currentPane, currentPane.isGranted else { return false }
        closePanel()
        return true
    }

    private func waitForPermissionResolutionAfterDrop() {
        guard let currentPane else { return }
        permissionResolutionTask?.cancel()
        panel?.hideForPermissionResolution()

        permissionResolutionTask = Task { @MainActor [weak self] in
            let isGranted = await PermissionResolutionWatcher.waitForResolution(
                pane: currentPane,
                timeout: .seconds(10)
            )
            guard let self, Task.isCancelled == false else { return }
            self.permissionResolutionTask = nil

            if isGranted {
                self.closePanel()
                return
            }

            if let frame = self.tracker.currentFrame {
                self.showPanel(for: frame)
            } else {
                self.showPanel()
            }
        }
    }
}

private extension Array where Element == URL {
    /// Normalizes and de-duplicates `.app` bundle URLs.
    func uniqueAppURLs() -> [URL] {
        var seen = Set<String>()
        return compactMap { url in
            let normalized = url.standardizedFileURL
            guard normalized.pathExtension.lowercased() == "app" else { return nil }
            return seen.insert(normalized.path).inserted ? normalized : nil
        }
    }

    /// Uses normalized file paths for containment because equivalent file URLs
    /// can differ in their string representation.
    func contains(_ url: URL) -> Bool {
        contains(where: { $0.standardizedFileURL.path == url.standardizedFileURL.path })
    }
}

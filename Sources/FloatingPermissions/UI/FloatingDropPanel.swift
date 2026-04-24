import AppKit
import QuartzCore

@MainActor
final class FloatingDropPanel: NSPanel {
    private weak var panelController: FloatingPermissionsController?
    private let panelSize = NSSize(width: 530, height: 109)

    private let sidebarWidth: CGFloat = 170
    private let settingsInset: CGFloat = 14
    private let screenInset: CGFloat = 8
    private let animationDuration: TimeInterval = 0.52
    private let animationResponse: Double = 0.62
    private let initialAlpha: CGFloat = 0.9

    private var launchTimer: Timer?
    private var launchStartTime: CFTimeInterval = 0
    private var launchFromFrame = NSRect.zero
    private var launchToFrame = NSRect.zero
    private var isAnimatingLaunch = false

    init(controller: FloatingPermissionsController) {
        panelController = controller

        super.init(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .statusBar
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        animationBehavior = .none

        contentView = FloatingDropPanelContentView(
            controller: controller,
            frame: NSRect(origin: .zero, size: panelSize)
        )
        setContentSize(panelSize)
    }

    override var canBecomeKey: Bool { false }

    override var canBecomeMain: Bool { false }

    override func close() {
        stopLaunchAnimation()
        super.close()
    }

    override func becomeKey() {
        super.becomeKey()
        panelController?.keepSettingsVisible()
    }

    override func becomeMain() {
        super.becomeMain()
        panelController?.keepSettingsVisible()
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || event.type == .rightMouseDown {
            panelController?.keepSettingsVisible()
        }
        super.sendEvent(event)
    }

    func show() {
        alphaValue = 1
        orderFrontRegardless()
    }

    func show(at sourceFrameInScreen: CGRect) {
        stopLaunchAnimation()
        isAnimatingLaunch = false
        alphaValue = 1
        setFrame(launchSourceFrame(for: sourceFrameInScreen), display: false)
        orderFrontRegardless()
    }

    func present(from sourceFrameInScreen: CGRect, to settingsFrame: CGRect) {
        stopLaunchAnimation()
        let targetFrame = targetFrame(for: settingsFrame)

        guard sourceFrameInScreen.isEmpty == false else {
            isAnimatingLaunch = false
            alphaValue = 1
            setFrame(targetFrame, display: false)
            orderFrontRegardless()
            return
        }

        isAnimatingLaunch = true
        launchFromFrame = launchSourceFrame(for: sourceFrameInScreen)
        launchToFrame = targetFrame
        launchStartTime = CACurrentMediaTime()
        alphaValue = initialAlpha
        setFrame(launchFromFrame, display: false)
        orderFrontRegardless()
        stepLaunchAnimation()

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stepLaunchAnimation()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        launchTimer = timer
    }

    func setDraggingPassthrough(_ isDragging: Bool) {
        ignoresMouseEvents = isDragging
        alphaValue = isDragging ? 0.72 : 1.0
        if isDragging {
            orderBack(nil)
        } else {
            orderFrontRegardless()
        }
    }

    func hideForPermissionResolution() {
        orderOut(nil)
    }

    func snap(to settingsFrame: CGRect) {
        let target = targetFrame(for: settingsFrame)
        if isAnimatingLaunch {
            launchToFrame = target
            return
        }

        stopLaunchAnimation()
        alphaValue = 1
        setFrame(target, display: false)
        orderFrontRegardless()
    }

    private func targetFrame(for settingsFrame: CGRect) -> CGRect {
        let screenFrame = NSScreen.screens
            .first(where: { $0.frame.intersects(settingsFrame) })?
            .visibleFrame ?? settingsFrame

        let contentMinX = settingsFrame.minX + sidebarWidth
        let contentWidth = max(settingsFrame.width - sidebarWidth, panelSize.width)
        let preferredX = contentMinX + ((contentWidth - panelSize.width) / 2) - 8
        let preferredY = settingsFrame.minY + settingsInset

        let x = min(max(preferredX, screenFrame.minX + screenInset), screenFrame.maxX - panelSize.width - screenInset)
        let y = min(max(preferredY, screenFrame.minY + screenInset), screenFrame.maxY - panelSize.height - screenInset)

        return NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
    }

    private func launchSourceFrame(for sourceFrameInScreen: CGRect) -> CGRect {
        NSRect(
            x: sourceFrameInScreen.midX - panelSize.width / 2,
            y: sourceFrameInScreen.midY - panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
    }

    private func stepLaunchAnimation() {
        let elapsed = max(0, CACurrentMediaTime() - launchStartTime)
        if elapsed >= animationDuration {
            isAnimatingLaunch = false
            stopLaunchAnimation()
            alphaValue = 1
            setFrame(launchToFrame, display: true)
            return
        }

        let progress = springProgress(at: elapsed)
        alphaValue = initialAlpha + ((1 - initialAlpha) * progress)
        setFrame(curvedFrame(from: launchFromFrame, to: launchToFrame, progress: progress), display: true)
    }

    private func stopLaunchAnimation() {
        launchTimer?.invalidate()
        launchTimer = nil
    }

    private func springProgress(at elapsed: TimeInterval) -> CGFloat {
        let omega = (2 * Double.pi) / animationResponse
        let progress = 1 - exp(-omega * elapsed) * (1 + (omega * elapsed))
        return min(max(progress, 0), 1)
    }

    private func curvedFrame(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let startCenter = CGPoint(x: from.midX, y: from.midY)
        let endCenter = CGPoint(x: to.midX, y: to.midY)
        let midpoint = CGPoint(
            x: (startCenter.x + endCenter.x) * 0.5,
            y: max(startCenter.y, endCenter.y)
        )
        let distance = hypot(endCenter.x - startCenter.x, endCenter.y - startCenter.y)
        let lift = min(140, max(44, distance * 0.18))
        let controlPoint = CGPoint(x: midpoint.x, y: midpoint.y + lift)
        let inverse = 1 - progress
        let center = CGPoint(
            x: (inverse * inverse * startCenter.x) + (2 * inverse * progress * controlPoint.x) + (progress * progress * endCenter.x),
            y: (inverse * inverse * startCenter.y) + (2 * inverse * progress * controlPoint.y) + (progress * progress * endCenter.y)
        )

        return CGRect(
            x: center.x - (from.width * 0.5),
            y: center.y - (from.height * 0.5),
            width: from.width,
            height: from.height
        )
    }
}

private final class FloatingDropPanelContentView: NSView {
    private weak var controller: FloatingPermissionsController?
    private let materialView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let arrowView = NSImageView()
    private var dragSource: AppDragSourceView?

    init(controller: FloatingPermissionsController, frame: NSRect) {
        self.controller = controller
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
        configure(controller: controller)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.material = .popover
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 18
        materialView.layer?.masksToBounds = true
        materialView.layer?.borderWidth = 0.5
        materialView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.18).cgColor
        addSubview(materialView)

        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.78).cgColor
        materialView.addSubview(tintView)

        let backChrome = NSView()
        backChrome.translatesAutoresizingMaskIntoConstraints = false
        backChrome.wantsLayer = true
        backChrome.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        backChrome.layer?.cornerRadius = 16
        materialView.addSubview(backChrome)

        let backButton = NSButton()
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isBordered = false
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")
        backButton.contentTintColor = NSColor.labelColor.withAlphaComponent(0.72)
        backButton.target = self
        backButton.action = #selector(backPressed)
        if let cell = backButton.cell as? NSButtonCell {
            cell.imagePosition = .imageOnly
        }
        backChrome.addSubview(backButton)

        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        arrowView.symbolConfiguration = .init(pointSize: 28, weight: .bold)
        arrowView.contentTintColor = NSColor(calibratedRed: 0.15, green: 0.54, blue: 0.98, alpha: 1)
        materialView.addSubview(arrowView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        materialView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 530),
            heightAnchor.constraint(equalToConstant: 109),

            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: materialView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: materialView.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: materialView.bottomAnchor),

            backChrome.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 18),
            backChrome.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 52),
            backChrome.widthAnchor.constraint(equalToConstant: 32),
            backChrome.heightAnchor.constraint(equalToConstant: 32),

            backButton.centerXAnchor.constraint(equalTo: backChrome.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backChrome.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 14),
            backButton.heightAnchor.constraint(equalToConstant: 14),

            arrowView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 35),
            arrowView.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 10),
            arrowView.widthAnchor.constraint(equalToConstant: 28),
            arrowView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: arrowView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -22)
        ])
    }

    private func configure(controller: FloatingPermissionsController) {
        titleLabel.attributedStringValue = title(controller: controller)

        guard let appURL = controller.preferredAppURL else { return }
        let dragSource = AppDragSourceView(url: appURL)
        dragSource.translatesAutoresizingMaskIntoConstraints = false
        dragSource.onDragStateChange = { [weak controller] isDragging, operation in
            Task { @MainActor in
                controller?.setPanelDragging(isDragging, completedOperation: operation)
            }
        }
        materialView.addSubview(dragSource)
        self.dragSource = dragSource

        NSLayoutConstraint.activate([
            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 64),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -21),
            dragSource.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 47),
            dragSource.heightAnchor.constraint(equalToConstant: 43)
        ])
    }

    private func title(controller: FloatingPermissionsController) -> NSAttributedString {
        let appName = controller.preferredAppURL.map { FileManager.default.displayName(atPath: $0.path) } ?? "this app"
        let paneTitle = controller.currentPane?.displayTitle ?? "Permission"
        return NSAttributedString(
            string: "Drag \(appName) to the list above to allow \(paneTitle)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.82)
            ]
        )
    }

    @objc
    private func backPressed() {
        controller?.closePanel()
    }
}

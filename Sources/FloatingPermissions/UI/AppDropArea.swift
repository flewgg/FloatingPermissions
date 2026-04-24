import AppKit
import SwiftUI

struct AppDragItemView: NSViewRepresentable {
    let url: URL
    let onDragStateChange: (Bool, NSDragOperation?) -> Void

    func makeNSView(context: Context) -> AppDragSourceView {
        let view = AppDragSourceView(url: url)
        view.onDragStateChange = onDragStateChange
        return view
    }

    func updateNSView(_ nsView: AppDragSourceView, context: Context) {
        nsView.update(url: url)
        nsView.onDragStateChange = onDragStateChange
    }
}

final class AppDragSourceView: NSView, NSDraggingSource {
    private var url: URL
    private let hostingView: NSHostingView<AnyView>
    private var mouseDownPoint: NSPoint?
    private var hasBegunDragging = false

    /// Tells the panel when it should temporarily become mouse-transparent.
    var onDragStateChange: ((Bool, NSDragOperation?) -> Void)?

    init(url: URL) {
        self.url = url
        self.hostingView = NSHostingView(rootView: AnyView(AppDragCardContent(url: url).allowsHitTesting(false)))
        super.init(frame: .zero)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(url: URL) {
        self.url = url
        hostingView.rootView = AnyView(AppDragCardContent(url: url).allowsHitTesting(false))
        invalidateIntrinsicContentSize()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        return self
    }

    override var intrinsicContentSize: NSSize {
        let fitting = hostingView.fittingSize
        return NSSize(width: NSView.noIntrinsicMetric, height: max(88, fitting.height))
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownPoint = convert(event.locationInWindow, from: nil)
        hasBegunDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard hasBegunDragging == false, let mouseDownPoint else { return }

        let currentPoint = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentPoint.x - mouseDownPoint.x, currentPoint.y - mouseDownPoint.y)
        guard distance > 4 else { return }

        hasBegunDragging = true
        beginAppDrag(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        mouseDownPoint = nil
        hasBegunDragging = false
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        true
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        onDragStateChange?(true, nil)
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onDragStateChange?(false, operation)
        mouseDownPoint = nil
        hasBegunDragging = false
    }

    private func beginAppDrag(with event: NSEvent) {
        // System Settings accepts drags more reliably when the payload looks
        // close to a Finder-originated file drag.
        let writer = AppBundlePasteboardWriter(url: url)
        let draggingItem = NSDraggingItem(pasteboardWriter: writer)
        let dragImage = AppDragPreviewImage.make(for: url)
        let dragPoint = convert(event.locationInWindow, from: nil)
        let dragFrame = NSRect(
            x: dragPoint.x - 28,
            y: dragPoint.y - (dragImage.size.height * 0.5),
            width: dragImage.size.width,
            height: dragImage.size.height
        )
        draggingItem.setDraggingFrame(dragFrame, contents: dragImage)

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
        session.draggingFormation = .none
    }
}

private enum AppDragPreviewImage {
    private static let iconSize: CGFloat = 40
    private static let horizontalPadding: CGFloat = 10
    private static let verticalPadding: CGFloat = 8
    private static let textSpacing: CGFloat = 8
    private static let maxTextWidth: CGFloat = 180

    static func make(for url: URL) -> NSImage {
        let displayName = FileManager.default.displayName(atPath: url.path)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingMiddle

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        let measuredTextSize = (displayName as NSString).size(withAttributes: attributes)
        let textWidth = min(maxTextWidth, max(72, ceil(measuredTextSize.width)))
        let height = iconSize + (verticalPadding * 2)
        let width = horizontalPadding + iconSize + textSpacing + textWidth + horizontalPadding
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        let imageRect = NSRect(origin: .zero, size: image.size)
        NSColor.clear.setFill()
        imageRect.fill()

        let background = NSBezierPath(roundedRect: imageRect, xRadius: 12, yRadius: 12)
        NSColor.windowBackgroundColor.withAlphaComponent(0.9).setFill()
        background.fill()
        NSColor.separatorColor.withAlphaComponent(0.45).setStroke()
        background.lineWidth = 1
        background.stroke()

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: iconSize, height: iconSize)
        icon.draw(
            in: NSRect(
                x: horizontalPadding,
                y: verticalPadding,
                width: iconSize,
                height: iconSize
            ),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )

        let textHeight = ceil(measuredTextSize.height)
        (displayName as NSString).draw(
            in: NSRect(
                x: horizontalPadding + iconSize + textSpacing,
                y: (height - textHeight) * 0.5,
                width: textWidth,
                height: textHeight
            ),
            withAttributes: attributes
        )

        image.unlockFocus()
        return image
    }
}

private final class AppBundlePasteboardWriter: NSObject, NSPasteboardWriting {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        [
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
            .string
        ]
    }

    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .fileURL, .URL, NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"):
            return url.absoluteString
        case NSPasteboard.PasteboardType("NSFilenamesPboardType"):
            return [url.path]
        case .string:
            return url.path
        default:
            return nil
        }
    }
}

private struct AppDragCardContent: View {
    let url: URL

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 32, height: 32)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
            }
            Spacer()
            VStack(spacing: 0) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 14, weight: .regular))
                Text("Drag")
                    .font(.system(size: 8, weight: .light))
            }
            .foregroundStyle(.secondary)
            .padding(.trailing, 6)
        }
        .padding(6)
        .background(.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.085), style: StrokeStyle(lineWidth: 1, dash: []))
        )
    }
}

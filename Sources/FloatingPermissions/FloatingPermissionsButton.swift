import AppKit
import SwiftUI

public struct FloatingPermissionsButton: View {
    @StateObject private var controller: FloatingPermissionsController
    @State private var sourceFrameInScreen = CGRect.zero

    private let pane: FloatingPermissionPane
    private let suggestedAppURLs: [URL]
    private let title: LocalizedStringResource?

    public init(
        title: LocalizedStringResource? = nil,
        pane: FloatingPermissionPane,
        suggestedAppURLs: [URL] = [],
        configuration: FloatingPermissionsConfiguration = .init()
    ) {
        _controller = StateObject(wrappedValue: FloatingPermissionsController(configuration: configuration))
        self.pane = pane
        self.suggestedAppURLs = suggestedAppURLs
        self.title = title
    }

    public var body: some View {
        Button {
            controller.authorize(
                pane: pane,
                suggestedAppURLs: suggestedAppURLs,
                sourceFrameInScreen: launchSourceFrameInScreen()
            )
        } label: {
            Label {
                Text(title ?? "Open")
            } icon: {
                Image(systemName: "arrow.up.right.circle.fill")
            }
        }
        .background(ScreenFrameReader(frameInScreen: $sourceFrameInScreen))
    }

    private func launchSourceFrameInScreen() -> CGRect {
        sourceFrameInScreen.isEmpty ? clickSourceFrameInScreen() : sourceFrameInScreen
    }

    /// Uses the click location as a fallback when the button frame is not available yet.
    private func clickSourceFrameInScreen() -> CGRect {
        let mouse = NSEvent.mouseLocation
        return CGRect(x: mouse.x - 16, y: mouse.y - 16, width: 32, height: 32)
    }
}

private struct ScreenFrameReader: NSViewRepresentable {
    @Binding var frameInScreen: CGRect

    func makeNSView(context: Context) -> ScreenFrameTrackingView {
        let view = ScreenFrameTrackingView()
        view.onFrameChange = { frame in
            if frameInScreen != frame {
                frameInScreen = frame
            }
        }
        return view
    }

    func updateNSView(_ nsView: ScreenFrameTrackingView, context: Context) {
        nsView.onFrameChange = { frame in
            if frameInScreen != frame {
                frameInScreen = frame
            }
        }
        nsView.reportFrame()
    }
}

private final class ScreenFrameTrackingView: NSView {
    var onFrameChange: ((CGRect) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportFrame()
    }

    override func layout() {
        super.layout()
        reportFrame()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        reportFrame()
    }

    func reportFrame() {
        guard let window else { return }
        let frame = window.convertToScreen(convert(bounds, to: nil))
        DispatchQueue.main.async { [onFrameChange] in
            onFrameChange?(frame)
        }
    }
}

import AppKit
import FloatingPermissions
import SwiftUI

struct ContentView: View {
    private let panes: [FloatingPermissionPane] = [
        .accessibility,
        .inputMonitoring
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(panes, id: \.self) { pane in
                        PermissionPaneCard(
                            pane: pane,
                            suggestedAppURL: Bundle.main.bundleURL
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("FloatingPermissions")
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}

private struct PermissionPaneCard: View {
    let pane: FloatingPermissionPane
    let suggestedAppURL: URL

    @StateObject private var controller = FloatingPermissions.makeController()
    @State private var sourceFrameInScreen = CGRect.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: pane.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(pane.tint)
                    .frame(width: 28, height: 28)

                Text(pane.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button {
                controller.authorize(
                    pane: pane,
                    suggestedAppURLs: [suggestedAppURL],
                    sourceFrameInScreen: sourceFrameInScreen
                )
            } label: {
                Label("Open", systemImage: "arrow.up.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .background(ScreenFrameReader(frameInScreen: $sourceFrameInScreen))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
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

private extension FloatingPermissionPane {
    var symbolName: String {
        switch self {
        case .accessibility: "figure.wave"
        case .inputMonitoring: "keyboard"
        }
    }

    var tint: Color {
        switch self {
        case .accessibility: .blue
        case .inputMonitoring: .mint
        }
    }
}

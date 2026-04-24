import AppKit
import SwiftUI

public struct FloatingPermissionsButton: View {
    @StateObject private var controller: FloatingPermissionsController

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
                sourceFrameInScreen: clickSourceFrameInScreen()
            )
        } label: {
            Label {
                Text(title ?? "Open")
            } icon: {
                Image(systemName: "arrow.up.right.circle.fill")
            }
        }
    }

    /// Uses the click location as the launch point so the helper flies out from the pressed button.
    private func clickSourceFrameInScreen() -> CGRect {
        let mouse = NSEvent.mouseLocation
        return CGRect(x: mouse.x - 16, y: mouse.y - 16, width: 32, height: 32)
    }
}

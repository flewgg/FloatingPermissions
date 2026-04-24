import SwiftUI

struct FloatingPermissionPanelView: View {
    @ObservedObject var controller: FloatingPermissionsController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if let primaryApp = controller.preferredAppURL {
                AppDragItemView(url: primaryApp) { isDragging, completedOperation in
                    controller.setPanelDragging(isDragging, completedOperation: completedOperation)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.primary.opacity(0.14), lineWidth: 1)
                )
        )
    }

    /// Keeps the header logic isolated from the drag card layout.
    private var header: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(headerTitle).font(.system(size: 14))
            Spacer()
            HStack(alignment: .top, spacing: 3) {
                if controller.isSettingsFrontmost == false {
                    Button {
                        controller.reopenCurrentSettingsPane()
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 15, weight: .semibold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.primary, .secondary.opacity(0.35))
                    }
                    .buttonStyle(.borderless)
                }
                Button {
                    controller.closePanel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.primary, .secondary.opacity(0.35))
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// Builds a markdown-backed title such as:
    /// "Drag **Example** to the list above to allow **Accessibility**."
    private var headerTitle: AttributedString {
        let markdown = String(
            format: "Drag **%@** to the list above to allow **%@**.",
            appDisplayName,
            paneDisplayTitle
        )

        return (try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
    }

    /// Prefers the Finder-style display name so the title reads naturally even
    /// when the URL contains a plain bundle filename.
    private var appDisplayName: String {
        guard let appURL = controller.preferredAppURL else {
            return "This App"
        }

        return FileManager.default.displayName(atPath: appURL.path)
    }

    /// Uses the current pane title so each permission can render a specific instruction.
    private var paneDisplayTitle: String {
        controller.currentPane?.displayTitle ?? "Permission"
    }
}

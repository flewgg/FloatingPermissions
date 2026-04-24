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

            FloatingPermissionsButton(
                title: "Open",
                pane: pane,
                suggestedAppURLs: [suggestedAppURL]
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
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

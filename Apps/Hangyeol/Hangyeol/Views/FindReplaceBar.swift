import SwiftUI

/// Find/Replace chrome. Live replace is gated by `presentation.canReplace`
/// (`document.session.canReplace`). Mock / closed sessions never fake success.
struct FindReplaceBar: View {
    @Binding var query: String
    @Binding var replacement: String
    var presentation: FindReplacePresentation
    var onFind: () -> Void = {}
    var onReplace: () -> Void = {}
    var onClose: () -> Void = {}

    @AccessibilityFocusState private var statusFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField(L10n.findPlaceholder, text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
                    .accessibilityLabel(L10n.findPlaceholder)
                    .accessibilityIdentifier("find-replace-query")
                TextField(L10n.replacePlaceholder, text: $replacement)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
                    .accessibilityLabel(L10n.replacePlaceholder)
                    .accessibilityIdentifier("find-replace-replacement")
                Button(L10n.findNext, action: onFind)
                    .disabled(!presentation.isFindNextEnabled)
                    .help(L10n.findNext)
                Button(L10n.replace, action: onReplace)
                    .disabled(!presentation.isReplaceEnabled)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help(L10n.replace)
                    .accessibilityIdentifier("find-replace-replace")
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .help(L10n.close)
                .accessibilityLabel(L10n.close)
            }
            Text(presentation.statusCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.updatesFrequently)
                .accessibilityFocused($statusFocused)
                .accessibilityIdentifier("find-replace-status")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityIdentifier("find-replace-bar")
        .onChange(of: presentation.statusFocusToken) { _, token in
            if token > 0, presentation.lastReplacementCount != nil {
                statusFocused = true
            }
        }
    }
}

#Preview("세션 있음") {
    FindReplaceBar(
        query: .constant("1"),
        replacement: .constant("HGPOC99"),
        presentation: .make(
            canReplace: true,
            query: "1",
            lastReplacementCount: nil
        )
    )
}

#Preview("스텁") {
    FindReplaceBar(
        query: .constant("본문"),
        replacement: .constant(""),
        presentation: .make(
            canReplace: false,
            query: "본문",
            lastReplacementCount: nil
        )
    )
}

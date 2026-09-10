import SwiftUI

/// One filename + one status line while PDF export runs.
struct ExportProgressSheet: View {
    let presentation: ExportProgressPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .accessibilityHidden(true)
            Text(presentation.filename)
                .font(.headline)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Text(presentation.status)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(minWidth: 320, maxWidth: 480, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityIdentifier("export-progress-sheet")
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    ExportProgressSheet(
        presentation: .make(filename: "허브-A.pdf")
    )
}

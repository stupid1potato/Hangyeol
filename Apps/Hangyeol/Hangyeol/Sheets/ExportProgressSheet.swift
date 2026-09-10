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
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("export-progress-filename")
            Text(presentation.status)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("export-progress-status")
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

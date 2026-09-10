import SwiftUI

struct StructuredTextView: View {
    @Binding var model: DocumentModel
    /// When true, table cells use the in-memory edit sketch (`TextField` + Binding).
    var tablesEditable: Bool = false
    /// Per-table `(row, col, text)` hook for a future `DocumentSession.setCellText`.
    var onTableCellCommit: ((Int, Int, String) -> Void)? = nil

    init(
        model: Binding<DocumentModel>,
        tablesEditable: Bool = false,
        onTableCellCommit: ((Int, Int, String) -> Void)? = nil
    ) {
        self._model = model
        self.tablesEditable = tablesEditable
        self.onTableCellCommit = onTableCellCommit
    }

    /// Read-only document snapshot (paragraphs + tables as `Text`).
    init(model: DocumentModel) {
        self._model = .constant(model)
        self.tablesEditable = false
        self.onTableCellCommit = nil
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(Array(model.blocks.enumerated()), id: \.element.id) { index, block in
                    switch block {
                    case .paragraph(let paragraph):
                        paragraphView(paragraph)
                    case .table:
                        TableBlockView(
                            table: DocumentModelTableBinding.binding(model: $model, atBlock: index),
                            editable: tablesEditable,
                            onCommit: onTableCellCommit
                        )
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 880, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    @ViewBuilder
    private func paragraphView(_ paragraph: ParagraphBlock) -> some View {
        paragraph.runs.reduce(Text("")) { partial, run in
            var piece = Text(run.text)
            if run.isBold { piece = piece.bold() }
            if run.isItalic { piece = piece.italic() }
            return partial + piece
        }
        .font(.body)
        .lineSpacing(6)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("읽기 전용") {
    StructuredTextView(model: MockEngine.sampleDocument())
}

#Preview("표 편집 스케치") {
    StructuredTextEditPreviewHost()
}

private struct StructuredTextEditPreviewHost: View {
    @State private var model = MockEngine.sampleDocument()

    var body: some View {
        StructuredTextView(model: $model, tablesEditable: true)
    }
}

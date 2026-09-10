import SwiftUI

struct StructuredTextView: View {
    let model: DocumentModel
    var canEditCells: Bool = false
    var engineTables: [TableInfo] = []
    /// `(engineTableIndex, row, col, text)` — parent calls `document.setCellText`.
    var onTableCellCommit: ((UInt32, Int, Int, String) -> Void)? = nil

    private var items: [StructuredTextItem] {
        TableEditMapping.items(
            model: model,
            engineTables: engineTables,
            canEditCells: canEditCells
        )
    }

    private var presentation: TableCellEditPresentation {
        .make(canEditCells: canEditCells)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let caption = presentation.caption, items.contains(where: \.isEditableTable) {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("table-edit-live-note")
                }

                ForEach(items) { item in
                    switch item {
                    case .paragraph(let paragraph):
                        paragraphView(paragraph)
                    case .table(let surface):
                        TableBlockView(
                            table: surface.table,
                            editable: surface.editable,
                            onCommit: { row, col, text in
                                guard let engineIndex = surface.engineIndex else { return }
                                onTableCellCommit?(engineIndex, row, col, text)
                            }
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

#Preview("표 세션 편집") {
    StructuredTextView(
        model: MockEngine.sampleDocument(),
        canEditCells: true,
        engineTables: [
            TableInfo(index: 0, section: 0, paragraph: 3, control: 0, rows: 4, cols: 2)
        ]
    )
}

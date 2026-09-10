import SwiftUI

struct StructuredTextView: View {
    let model: DocumentModel
    var canEditCells: Bool = false
    var canEditParagraphs: Bool = false
    var engineTables: [TableInfo] = []
    /// `(engineTableIndex, row, col, text)` — parent calls `document.setCellText`.
    var onTableCellCommit: ((UInt32, Int, Int, String) -> Void)? = nil
    /// `(section, paragraph, oldText, newText)` — parent calls `document.insertText` / `deleteRange`.
    var onParagraphCommit: ((UInt32, UInt32, String, String) -> Void)? = nil

    private var items: [StructuredTextItem] {
        TableEditMapping.items(
            model: model,
            engineTables: engineTables,
            canEditCells: canEditCells,
            canEditParagraphs: canEditParagraphs
        )
    }

    private var tablePresentation: TableCellEditPresentation {
        .make(canEditCells: canEditCells)
    }

    private var paragraphPresentation: ParagraphEditPresentation {
        .make(canEditParagraphs: canEditParagraphs)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let caption = paragraphPresentation.caption, items.contains(where: \.isEditableParagraph) {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("paragraph-edit-live-note")
                }

                if let caption = tablePresentation.caption, items.contains(where: \.isEditableTable) {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("table-edit-live-note")
                }

                ForEach(items) { item in
                    switch item {
                    case .paragraph(let surface):
                        paragraphView(surface)
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
    private func paragraphView(_ surface: ParagraphEditSurface) -> some View {
        if surface.editable {
            ParagraphEditorView(
                surface: surface,
                onCommit: { oldText, newText in
                    guard let address = surface.engineAddress else { return }
                    onParagraphCommit?(address.section, address.paragraph, oldText, newText)
                }
            )
        } else {
            surface.paragraph.runs.reduce(Text("")) { partial, run in
                var piece = Text(run.text)
                if run.isBold { piece = piece.bold() }
                if run.isItalic { piece = piece.italic() }
                return partial + piece
            }
            .font(.body)
            .lineSpacing(6)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(
                ParagraphEditPresentation.accessibilityLabel(
                    ordinal: Int(surface.paragraphIndex ?? 0),
                    text: surface.plainText,
                    editable: false
                )
            )
            .accessibilityIdentifier(paragraphIdentifier(surface))
        }
    }

    private func paragraphIdentifier(_ surface: ParagraphEditSurface) -> String {
        "document-paragraph-\(surface.paragraphIndex ?? 0)"
    }
}

/// Structured paragraph field (not WYSIWYG). TextField undo covers in-progress
/// typing; session undo/redo is out of scope.
private struct ParagraphEditorView: View {
    let surface: ParagraphEditSurface
    var onCommit: (String, String) -> Void

    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $draft, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(1...20)
            .lineSpacing(6)
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { draft = surface.plainText }
            .onChange(of: surface.plainText) { _, newValue in
                if !isFocused { draft = newValue }
            }
            .onSubmit { commitIfNeeded() }
            .onChange(of: isFocused) { _, focused in
                if !focused { commitIfNeeded() }
            }
            .accessibilityLabel(
                ParagraphEditPresentation.accessibilityLabel(
                    ordinal: Int(surface.paragraphIndex ?? 0),
                    text: draft,
                    editable: true
                )
            )
            .accessibilityIdentifier("document-paragraph-\(surface.paragraphIndex ?? 0)")
    }

    private func commitIfNeeded() {
        guard surface.editable, draft != surface.plainText else { return }
        onCommit(surface.plainText, draft)
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

#Preview("문단 세션 편집") {
    StructuredTextView(
        model: DocumentModel(
            metadata: DocumentMetadata(title: "허브-A", sourceType: .hwpx),
            blocks: [
                .paragraph(ParagraphBlock(text: "본문")),
                .paragraph(ParagraphBlock(text: "1")),
                .paragraph(ParagraphBlock(text: "2"))
            ]
        ),
        canEditParagraphs: true
    )
}

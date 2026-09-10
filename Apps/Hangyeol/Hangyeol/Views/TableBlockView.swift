import SwiftUI

struct TableBlockView: View {
    @Binding var table: TableBlock
    var editable: Bool = false
    /// Future session hook `(row, col, text)`. Default is local Binding only.
    var onCommit: ((Int, Int, String) -> Void)? = nil

    private var presentation: TableCellEditPresentation {
        .make(editable: editable)
    }

    init(
        table: Binding<TableBlock>,
        editable: Bool = false,
        onCommit: ((Int, Int, String) -> Void)? = nil
    ) {
        self._table = table
        self.editable = editable
        self.onCommit = onCommit
    }

    /// Read-only snapshot (current `Text` look).
    init(table: TableBlock) {
        self._table = .constant(table)
        self.editable = false
        self.onCommit = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(Array(table.rows.enumerated()), id: \.element.id) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.cells.enumerated()), id: \.element.id) { columnIndex, cell in
                            TableCellView(
                                row: rowIndex,
                                column: columnIndex,
                                isHeader: cell.isHeader,
                                editable: editable,
                                text: cellTextBinding(row: rowIndex, col: columnIndex),
                                onCommit: onCommit
                            )
                        }
                    }
                    Divider()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                TableCellEditPresentation.tableAccessibilityLabel(
                    rowCount: table.rows.count,
                    columnCount: table.columnCount
                )
            )
            .accessibilityIdentifier("document-table")

            if let stubNote = presentation.stubNote {
                Text(stubNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("table-edit-sketch-note")
            }
        }
    }

    private func cellTextBinding(row: Int, col: Int) -> Binding<String> {
        Binding(
            get: { TableCellEditFlow.cellText(table, row: row, col: col) },
            set: { TableCellEditFlow.apply(&table, row: row, col: col, text: $0) }
        )
    }
}

private struct TableCellView: View {
    let row: Int
    let column: Int
    let isHeader: Bool
    let editable: Bool
    @Binding var text: String
    var onCommit: ((Int, Int, String) -> Void)?

    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if editable {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onAppear { draft = text }
                    .onChange(of: text) { _, newValue in
                        if !isFocused { draft = newValue }
                    }
                    .onSubmit { commitIfNeeded() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commitIfNeeded() }
                    }
            } else {
                Text(text)
            }
        }
        .font(isHeader ? .headline : .body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isHeader ? Color.secondary.opacity(0.16) : Color.clear)
        .overlay(alignment: .trailing) {
            Divider()
        }
        .accessibilityLabel(cellAccessibilityLabel)
        .accessibilityAddTraits(isHeader ? .isHeader : [])
        .accessibilityIdentifier("table-cell-\(row)-\(column)")
    }

    private var cellAccessibilityLabel: String {
        TableCellEditPresentation.cellAccessibilityLabel(
            row: row,
            column: column,
            text: editable ? draft : text,
            isHeader: isHeader
        )
    }

    private func commitIfNeeded() {
        guard draft != text else { return }
        text = draft
        onCommit?(row, column, draft)
    }
}

#Preview("읽기 전용") {
    TableBlockView(
        table: TableBlock(
            headers: ["항목", "내용"],
            body: [["형식", "HWPX"], ["엔진", "MockEngine"]]
        )
    )
    .padding()
}

#Preview("편집 스케치") {
    TableBlockEditPreviewHost()
        .padding()
}

private struct TableBlockEditPreviewHost: View {
    @State private var table = TableBlock(
        headers: ["항목", "내용"],
        body: [["형식", "HWPX"], ["엔진", "MockEngine"]]
    )

    var body: some View {
        TableBlockView(table: $table, editable: true)
    }
}

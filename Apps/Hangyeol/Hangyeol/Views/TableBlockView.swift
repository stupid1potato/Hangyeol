import SwiftUI

struct TableBlockView: View {
    let table: TableBlock
    var editable: Bool = false
    /// `(row, col, text)` after Return / focus loss. Parent maps to engine index.
    var onCommit: ((Int, Int, String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { columnIndex, cell in
                        TableCellView(
                            row: rowIndex,
                            column: columnIndex,
                            isHeader: cell.isHeader,
                            editable: editable,
                            text: cell.text,
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
    }
}

private struct TableCellView: View {
    let row: Int
    let column: Int
    let isHeader: Bool
    let editable: Bool
    let text: String
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
        guard editable, draft != text else { return }
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

#Preview("세션 편집") {
    TableBlockView(
        table: TableBlock(
            headers: ["항목", "내용"],
            body: [["형식", "HWPX"], ["엔진", "Real"]]
        ),
        editable: true
    )
    .padding()
}

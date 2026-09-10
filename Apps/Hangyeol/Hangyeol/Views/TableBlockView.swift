import SwiftUI

struct TableBlockView: View {
    let table: TableBlock

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(table.rows.enumerated()), id: \.element.id) { _, row in
                HStack(spacing: 0) {
                    ForEach(row.cells) { cell in
                        Text(cell.text)
                            .font(cell.isHeader ? .headline : .body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(cell.isHeader ? Color.secondary.opacity(0.16) : Color.clear)
                            .overlay(alignment: .trailing) {
                                Divider()
                            }
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
        .accessibilityLabel(tableAccessibilityLabel)
    }

    private var tableAccessibilityLabel: String {
        table.rows
            .map { row in row.cells.map(\.text).joined(separator: ", ") }
            .joined(separator: "; ")
    }
}

#Preview {
    TableBlockView(
        table: TableBlock(
            headers: ["항목", "내용"],
            body: [["형식", "HWPX"], ["엔진", "MockEngine"]]
        )
    )
    .padding()
}

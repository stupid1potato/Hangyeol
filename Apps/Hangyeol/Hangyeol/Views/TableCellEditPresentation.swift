import Foundation
import SwiftUI

/// Table cell chrome for the **in-memory** `TableBlock` sketch.
///
/// Sketch only: do not call `document.listTables` / `setCellText` /
/// `session.canEditCells`. After #22 merges, a follow-up binds `onCommit`.
struct TableCellEditPresentation: Equatable {
    var editable: Bool

    var usesField: Bool { editable }
    var showsStubNote: Bool { editable }

    var stubNote: String? {
        showsStubNote ? L10n.tableEditSketchNote : nil
    }

    static func make(editable: Bool) -> TableCellEditPresentation {
        TableCellEditPresentation(editable: editable)
    }

    /// 1-based 행/열 for VoiceOver. `row` / `column` are 0-based indices.
    static func cellAccessibilityLabel(
        row: Int,
        column: Int,
        text: String,
        isHeader: Bool
    ) -> String {
        L10n.tableCellA11y(
            row: row + 1,
            column: column + 1,
            text: text,
            isHeader: isHeader
        )
    }

    static func tableAccessibilityLabel(rowCount: Int, columnCount: Int) -> String {
        L10n.tableA11y(rows: rowCount, columns: columnCount)
    }
}

/// Local `TableBlock` mutation only. No engine / session side effects.
enum TableCellEditFlow {
    static func cellText(_ table: TableBlock, row: Int, col: Int) -> String {
        guard table.rows.indices.contains(row),
              table.rows[row].cells.indices.contains(col) else {
            return ""
        }
        return table.rows[row].cells[col].text
    }

    @discardableResult
    static func apply(_ table: inout TableBlock, row: Int, col: Int, text: String) -> Bool {
        guard table.rows.indices.contains(row),
              table.rows[row].cells.indices.contains(col) else {
            return false
        }
        table.rows[row].cells[col].text = text
        return true
    }

    /// Updates the in-memory cell, then optionally notifies a future session hook.
    @discardableResult
    static func commit(
        _ table: inout TableBlock,
        row: Int,
        col: Int,
        text: String,
        onCommit: ((Int, Int, String) -> Void)?
    ) -> Bool {
        guard apply(&table, row: row, col: col, text: text) else { return false }
        onCommit?(row, col, text)
        return true
    }
}

/// Binding helper so `StructuredTextView` can edit a table block without
/// touching `HangyeolDocument` session forwarding.
enum DocumentModelTableBinding {
    static func table(in model: DocumentModel, atBlock index: Int) -> TableBlock? {
        guard model.blocks.indices.contains(index),
              case .table(let table) = model.blocks[index] else {
            return nil
        }
        return table
    }

    @discardableResult
    static func replaceTable(in model: inout DocumentModel, atBlock index: Int, with table: TableBlock) -> Bool {
        guard model.blocks.indices.contains(index),
              case .table = model.blocks[index] else {
            return false
        }
        model.blocks[index] = .table(table)
        return true
    }

    static func binding(model: Binding<DocumentModel>, atBlock index: Int) -> Binding<TableBlock> {
        Binding(
            get: {
                DocumentModelTableBinding.table(in: model.wrappedValue, atBlock: index)
                    ?? TableBlock(columnCount: 0, rows: [])
            },
            set: { newTable in
                DocumentModelTableBinding.replaceTable(
                    in: &model.wrappedValue,
                    atBlock: index,
                    with: newTable
                )
            }
        )
    }
}

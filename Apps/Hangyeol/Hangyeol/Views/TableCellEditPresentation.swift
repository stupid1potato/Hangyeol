import Foundation

/// Table chrome gated by **this** document's `session.canEditCells`.
/// Views must not call HangyeolKit `RealEngine` or process-wide `EngineClient`.
struct TableCellEditPresentation: Equatable {
    var canEditCells: Bool

    var usesField: Bool { canEditCells }

    /// Live session only. Mock / closed sessions stay silent (no fake success).
    var caption: String? {
        canEditCells ? L10n.tableEditLiveNote : nil
    }

    static func make(canEditCells: Bool) -> TableCellEditPresentation {
        TableCellEditPresentation(canEditCells: canEditCells)
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

/// One on-screen table plus optional engine `TableInfo.index` for `setCellText`.
struct TableEditSurface: Equatable, Identifiable {
    var id: String
    var engineIndex: UInt32?
    var table: TableBlock
    var editable: Bool
}

enum StructuredTextItem: Equatable, Identifiable {
    case paragraph(ParagraphBlock)
    case table(TableEditSurface)

    var id: String {
        switch self {
        case .paragraph(let paragraph):
            return "p-\(paragraph.id.uuidString)"
        case .table(let surface):
            return "t-\(surface.id)"
        }
    }

    var isEditableTable: Bool {
        if case .table(let surface) = self {
            return surface.editable
        }
        return false
    }
}

/// Map display `.table` blocks (or live plain-text paragraphs) to `listTables()`
/// document order. `setCellText` always uses `TableInfo.index`, never the
/// display ordinal, and never guesses when row/col counts disagree.
enum TableEditMapping {
    static func items(
        model: DocumentModel,
        engineTables: [TableInfo],
        canEditCells: Bool
    ) -> [StructuredTextItem] {
        let displayTables = model.blocks.compactMap { block -> TableBlock? in
            if case .table(let table) = block { return table }
            return nil
        }

        if !displayTables.isEmpty {
            var ordinal = 0
            return model.blocks.map { block in
                switch block {
                case .paragraph(let paragraph):
                    return .paragraph(paragraph)
                case .table(let table):
                    let info = engineTables.indices.contains(ordinal) ? engineTables[ordinal] : nil
                    let engineIndex = engineIndexIfCompatible(display: table, info: info)
                    let surface = TableEditSurface(
                        id: table.id.uuidString,
                        engineIndex: engineIndex,
                        table: table,
                        editable: canEditCells && engineIndex != nil
                    )
                    ordinal += 1
                    return .table(surface)
                }
            }
        }

        guard canEditCells, !engineTables.isEmpty else {
            return model.blocks.compactMap { block in
                if case .paragraph(let paragraph) = block {
                    return .paragraph(paragraph)
                }
                return nil
            }
        }

        return synthesizedItems(from: model, engineTables: engineTables)
    }

    /// Display table ↔ engine table only when the grid size matches.
    static func engineIndexIfCompatible(display: TableBlock, info: TableInfo?) -> UInt32? {
        guard let info else { return nil }
        guard UInt32(display.rows.count) == info.rows,
              UInt32(display.columnCount) == info.cols else {
            return nil
        }
        return info.index
    }

    /// Kit `displayModel` flattens body + cell paragraphs. Trailing lines fill
    /// engine grids in document order (`rows * cols` slots per table).
    static func synthesizedItems(
        from model: DocumentModel,
        engineTables: [TableInfo]
    ) -> [StructuredTextItem] {
        let lines = model.blocks.compactMap { block -> String? in
            if case .paragraph(let paragraph) = block { return paragraph.plainText }
            return nil
        }
        let slotCounts = engineTables.map { Int($0.rows) * Int($0.cols) }
        let totalSlots = slotCounts.reduce(0, +)
        let bodyCount = max(0, lines.count - totalSlots)
        let bodyLines = Array(lines.prefix(bodyCount))
        var cellLines = Array(lines.dropFirst(bodyCount))

        var items: [StructuredTextItem] = bodyLines.map { .paragraph(ParagraphBlock(text: $0)) }
        for info in engineTables {
            let slots = Int(info.rows) * Int(info.cols)
            let values = Array(cellLines.prefix(slots))
            cellLines = Array(cellLines.dropFirst(min(slots, cellLines.count)))
            let table = TableBlockGrid.make(rows: Int(info.rows), cols: Int(info.cols), values: values)
            items.append(
                .table(
                    TableEditSurface(
                        id: "engine-\(info.index)",
                        engineIndex: info.index,
                        table: table,
                        editable: true
                    )
                )
            )
        }
        return items
    }
}

enum TableBlockGrid {
    static func make(rows: Int, cols: Int, values: [String]) -> TableBlock {
        let rowCount = max(rows, 0)
        let colCount = max(cols, 0)
        let rowModels: [TableRow] = (0..<rowCount).map { row in
            TableRow(
                cells: (0..<colCount).map { col in
                    let index = row * colCount + col
                    return TableCell(
                        text: index < values.count ? values[index] : "",
                        isHeader: false
                    )
                }
            )
        }
        return TableBlock(columnCount: colCount, rows: rowModels)
    }
}

/// View-layer cell commit: no fake success when the session cannot edit cells.
enum TableCellEditFlow {
    enum Outcome: Equatable {
        case skippedUnavailable
        case skippedUnmapped
        case updated
        case failed(HangyeolError)
    }

    static func commit(
        canEditCells: Bool,
        engineTableIndex: UInt32?,
        row: Int,
        col: Int,
        text: String,
        perform: (UInt32, UInt32, UInt32, String) throws -> Void
    ) -> Outcome {
        guard canEditCells else { return .skippedUnavailable }
        guard let engineTableIndex, row >= 0, col >= 0 else { return .skippedUnmapped }
        do {
            try perform(engineTableIndex, UInt32(row), UInt32(col), text)
            return .updated
        } catch let error as HangyeolError {
            return .failed(error)
        } catch {
            return .failed(.engineFailed(error.localizedDescription))
        }
    }
}

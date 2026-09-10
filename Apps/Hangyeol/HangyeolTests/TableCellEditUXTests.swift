import XCTest
@testable import Hangyeol

final class TableCellEditUXTests: XCTestCase {
    func testReadOnlyPresentationKeepsTextLook() {
        let presentation = TableCellEditPresentation.make(editable: false)
        XCTAssertFalse(presentation.usesField)
        XCTAssertFalse(presentation.showsStubNote)
        XCTAssertNil(presentation.stubNote)
    }

    func testEditablePresentationShowsSketchNote() {
        let presentation = TableCellEditPresentation.make(editable: true)
        XCTAssertTrue(presentation.usesField)
        XCTAssertTrue(presentation.showsStubNote)
        XCTAssertEqual(presentation.stubNote, L10n.tableEditSketchNote)
        XCTAssertTrue(L10n.tableEditSketchNote.contains("화면에만"))
        XCTAssertFalse(L10n.tableEditSketchNote.localizedCaseInsensitiveContains("성공"))
        XCTAssertFalse(L10n.tableEditSketchNote.localizedCaseInsensitiveContains("listTables"))
        XCTAssertFalse(L10n.tableEditSketchNote.localizedCaseInsensitiveContains("setCellText"))
    }

    func testCellAccessibilityUsesKoreanRowColumn() {
        let header = TableCellEditPresentation.cellAccessibilityLabel(
            row: 0,
            column: 1,
            text: "내용",
            isHeader: true
        )
        XCTAssertTrue(header.contains("1행"))
        XCTAssertTrue(header.contains("2열"))
        XCTAssertTrue(header.contains(L10n.tableHeaderRole))
        XCTAssertTrue(header.contains("내용"))

        let body = TableCellEditPresentation.cellAccessibilityLabel(
            row: 2,
            column: 0,
            text: "한국어",
            isHeader: false
        )
        XCTAssertTrue(body.contains("3행"))
        XCTAssertTrue(body.contains("1열"))
        XCTAssertTrue(body.contains("한국어"))
        XCTAssertFalse(body.contains(L10n.tableHeaderRole))
    }

    func testEmptyCellAccessibilityUsesPlaceholder() {
        let label = TableCellEditPresentation.cellAccessibilityLabel(
            row: 1,
            column: 1,
            text: "  ",
            isHeader: false
        )
        XCTAssertTrue(label.contains("2행"))
        XCTAssertTrue(label.contains("2열"))
        XCTAssertTrue(label.contains(L10n.tableEmptyCell))
    }

    func testTableAccessibilityUsesRowAndColumnCounts() {
        let label = TableCellEditPresentation.tableAccessibilityLabel(rowCount: 4, columnCount: 2)
        XCTAssertTrue(label.contains("표"))
        XCTAssertTrue(label.contains("4행"))
        XCTAssertTrue(label.contains("2열"))
    }

    func testCommitUpdatesInMemoryTableAndNotifiesCallback() {
        var table = TableBlock(headers: ["가", "나"], body: [["1", "2"]])
        var committed: (Int, Int, String)?
        let ok = TableCellEditFlow.commit(
            &table,
            row: 1,
            col: 1,
            text: "수정",
            onCommit: { row, col, text in
                committed = (row, col, text)
            }
        )
        XCTAssertTrue(ok)
        XCTAssertEqual(TableCellEditFlow.cellText(table, row: 1, col: 1), "수정")
        XCTAssertEqual(committed?.0, 1)
        XCTAssertEqual(committed?.1, 1)
        XCTAssertEqual(committed?.2, "수정")
        XCTAssertEqual(table.rows[0].cells[0].text, "가")
    }

    func testCommitOutOfBoundsIsNoOp() {
        var table = TableBlock(headers: ["가"], body: [["1"]])
        var called = false
        XCTAssertFalse(
            TableCellEditFlow.commit(
                &table,
                row: 9,
                col: 0,
                text: "x",
                onCommit: { _, _, _ in called = true }
            )
        )
        XCTAssertFalse(called)
        XCTAssertEqual(table.rows[1].cells[0].text, "1")
    }

    func testNilOnCommitStillUpdatesLocalBindingModel() {
        var table = TableBlock(headers: ["항목"], body: [["이전"]])
        XCTAssertTrue(TableCellEditFlow.commit(&table, row: 1, col: 0, text: "이후", onCommit: nil))
        XCTAssertEqual(table.rows[1].cells[0].text, "이후")
    }

    func testDocumentModelTableBindingReplacesOnlyTableBlocks() {
        var model = DocumentModel(
            metadata: DocumentMetadata(title: "시험", sourceType: .hwpx),
            blocks: [
                .paragraph(ParagraphBlock(text: "문단")),
                .table(TableBlock(headers: ["가"], body: [["1"]]))
            ]
        )
        XCTAssertNil(DocumentModelTableBinding.table(in: model, atBlock: 0))
        XCTAssertEqual(DocumentModelTableBinding.table(in: model, atBlock: 1)?.rows[1].cells[0].text, "1")

        var edited = DocumentModelTableBinding.table(in: model, atBlock: 1)!
        XCTAssertTrue(TableCellEditFlow.apply(&edited, row: 1, col: 0, text: "화면"))
        XCTAssertTrue(DocumentModelTableBinding.replaceTable(in: &model, atBlock: 1, with: edited))
        XCTAssertEqual(DocumentModelTableBinding.table(in: model, atBlock: 1)?.rows[1].cells[0].text, "화면")
        if case .paragraph(let paragraph) = model.blocks[0] {
            XCTAssertEqual(paragraph.plainText, "문단")
        } else {
            XCTFail("paragraph block should be unchanged")
        }
        XCTAssertFalse(DocumentModelTableBinding.replaceTable(in: &model, atBlock: 0, with: edited))
    }

    func testViewsDoNotCallDocumentListTablesOrSetCellText() throws {
        let views = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views")
        let files = try FileManager.default.contentsOfDirectory(
            at: views,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "swift" }
        XCTAssertFalse(files.isEmpty)

        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(
                source.contains("document.listTables("),
                "\(file.lastPathComponent) calls document.listTables"
            )
            XCTAssertFalse(
                source.contains("document.setCellText("),
                "\(file.lastPathComponent) calls document.setCellText"
            )
            XCTAssertFalse(
                source.contains(".canEditCells"),
                "\(file.lastPathComponent) reads canEditCells"
            )
        }
    }
}

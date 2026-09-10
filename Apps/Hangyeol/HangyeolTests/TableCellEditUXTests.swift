import XCTest
@testable import Hangyeol

private final class CellRecordingEngine: HangyeolLiveSession, @unchecked Sendable {
    var isOpen: Bool = true
    var listedTables: [TableInfo] = []
    var setCellCalls: [(UInt32, UInt32, UInt32, String)] = []
    var displayBlocks: [ContentBlock] = []
    var setCellError: Error?

    func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: "live", sourceType: type),
            blocks: [.paragraph(ParagraphBlock(text: String(data: data, encoding: .utf8) ?? ""))]
        )
    }

    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        Data("live|\(type.rawValue)".utf8)
    }

    func replaceText(find: String, replace: String) throws -> Int {
        _ = find
        _ = replace
        return 0
    }

    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: title, sourceType: type),
            blocks: displayBlocks
        )
    }

    func saveHwpx(to path: String) throws {
        try Data().write(to: URL(fileURLWithPath: path))
    }

    func listTables() throws -> [TableInfo] {
        listedTables
    }

    func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        if let setCellError {
            throw setCellError
        }
        setCellCalls.append((table, row, col, text))
    }

    func insertText(section: UInt32, paragraph: UInt32, charOffset: UInt32, text: String) throws {
        _ = section
        _ = paragraph
        _ = charOffset
        _ = text
    }

    func deleteRange(section: UInt32, paragraph: UInt32, charOffset: UInt32, count: UInt32) throws {
        _ = section
        _ = paragraph
        _ = charOffset
        _ = count
    }
}

final class TableCellEditUXTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EngineClient.useMockFlagKey)
        EngineClient.resetToDefault()
        super.tearDown()
    }

    func testReadOnlyWhenSessionCannotEditCells() {
        let presentation = TableCellEditPresentation.make(canEditCells: false)
        XCTAssertFalse(presentation.usesField)
        XCTAssertNil(presentation.caption)
    }

    func testMockDocumentSessionStaysReadOnly() {
        EngineClient.resetToMock()
        let document = HangyeolDocument(model: MockEngine.sampleDocument())
        XCTAssertTrue(document.session.isUsingMock)
        XCTAssertFalse(document.session.canEditCells)

        let presentation = TableCellEditPresentation.make(canEditCells: document.session.canEditCells)
        XCTAssertFalse(presentation.usesField)
        XCTAssertNil(presentation.caption)

        let items = TableEditMapping.items(
            model: document.model,
            engineTables: [],
            canEditCells: document.session.canEditCells
        )
        let tables = items.compactMap { item -> TableEditSurface? in
            if case .table(let surface) = item { return surface }
            return nil
        }
        XCTAssertFalse(tables.isEmpty)
        XCTAssertTrue(tables.allSatisfy { $0.engineIndex == nil && $0.editable == false })
    }

    func testLiveCaptionKeepsHubASmokeNote() {
        let presentation = TableCellEditPresentation.make(canEditCells: true)
        XCTAssertTrue(presentation.usesField)
        XCTAssertEqual(presentation.caption, L10n.tableEditLiveNote)
        XCTAssertTrue(L10n.tableEditLiveNote.contains("HGSET99"))
        XCTAssertTrue(L10n.tableEditLiveNote.contains("허브-A"))
        XCTAssertTrue(L10n.tableEditLiveNote.contains("HWPX"))
        XCTAssertFalse(L10n.tableEditLiveNote.localizedCaseInsensitiveContains("성공"))
        XCTAssertFalse(L10n.tableEditLiveNote.localizedCaseInsensitiveContains("Mock"))
        XCTAssertFalse(L10n.tableEditLiveNote.localizedCaseInsensitiveContains("XCFramework"))
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

    func testMappingUsesEngineIndexNotDisplayOrdinal() {
        let display = TableBlock(headers: ["가", "나"], body: [["1", "2"]])
        let info = TableInfo(index: 4, section: 0, paragraph: 2, control: 0, rows: 2, cols: 2)
        XCTAssertEqual(TableEditMapping.engineIndexIfCompatible(display: display, info: info), 4)

        let items = TableEditMapping.items(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "표", sourceType: .hwpx),
                blocks: [.table(display)]
            ),
            engineTables: [info],
            canEditCells: true
        )
        guard case .table(let surface) = items.first else {
            return XCTFail("expected table surface")
        }
        XCTAssertEqual(surface.engineIndex, 4)
        XCTAssertTrue(surface.editable)
    }

    func testDimensionMismatchDoesNotEnableEdit() {
        let display = TableBlock(headers: ["가"], body: [["1"]])
        let info = TableInfo(index: 0, section: 0, paragraph: 0, control: 0, rows: 3, cols: 3)
        XCTAssertNil(TableEditMapping.engineIndexIfCompatible(display: display, info: info))

        let items = TableEditMapping.items(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "표", sourceType: .hwpx),
                blocks: [.table(display)]
            ),
            engineTables: [info],
            canEditCells: true
        )
        guard case .table(let surface) = items.first else {
            return XCTFail("expected table surface")
        }
        XCTAssertNil(surface.engineIndex)
        XCTAssertFalse(surface.editable)
    }

    func testFlattenedParagraphsSynthesizeHubASizedGrid() {
        let lines = ["본문", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        let model = DocumentModel(
            metadata: DocumentMetadata(title: "허브-A", sourceType: .hwpx),
            blocks: lines.map { .paragraph(ParagraphBlock(text: $0)) }
        )
        let info = TableInfo(index: 0, section: 0, paragraph: 0, control: 0, rows: 3, cols: 3)
        let items = TableEditMapping.items(
            model: model,
            engineTables: [info],
            canEditCells: true
        )
        XCTAssertEqual(items.count, 2)
        guard case .paragraph(let body) = items[0] else {
            return XCTFail("expected leading body paragraph")
        }
        XCTAssertEqual(body.plainText, "본문")
        guard case .table(let surface) = items[1] else {
            return XCTFail("expected synthesized table")
        }
        XCTAssertEqual(surface.engineIndex, 0)
        XCTAssertTrue(surface.editable)
        XCTAssertEqual(surface.table.rows.count, 3)
        XCTAssertEqual(surface.table.columnCount, 3)
        XCTAssertEqual(surface.table.rows[0].cells[0].text, "1")
        XCTAssertEqual(surface.table.rows[2].cells[2].text, "9")
    }

    func testFlowSkipsMockWithoutCallingSession() {
        var called = false
        let outcome = TableCellEditFlow.commit(
            canEditCells: false,
            engineTableIndex: 0,
            row: 0,
            col: 0,
            text: "HGSET99"
        ) { _, _, _, _ in
            called = true
        }
        XCTAssertEqual(outcome, .skippedUnavailable)
        XCTAssertFalse(called)
    }

    func testFlowSkipsUnmappedEngineIndex() {
        var called = false
        let outcome = TableCellEditFlow.commit(
            canEditCells: true,
            engineTableIndex: nil,
            row: 0,
            col: 0,
            text: "HGSET99"
        ) { _, _, _, _ in
            called = true
        }
        XCTAssertEqual(outcome, .skippedUnmapped)
        XCTAssertFalse(called)
    }

    func testFlowCallsDocumentSetCellTextAndRefreshesModel() throws {
        let live = CellRecordingEngine()
        live.listedTables = [
            TableInfo(index: 0, section: 0, paragraph: 1, control: 0, rows: 3, cols: 3)
        ]
        live.displayBlocks = [
            .table(TableBlock(headers: ["a", "b", "c"], body: [["HGSET99", "2", "3"], ["4", "5", "6"]]))
        ]
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "허브", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: "1"))]
            ),
            session: DocumentSession(engine: live)
        )
        XCTAssertTrue(document.session.canEditCells)
        XCTAssertFalse(document.hasUnsavedEdits)

        EngineClient.current = MockEngine()

        let outcome = TableCellEditFlow.commit(
            canEditCells: document.session.canEditCells,
            engineTableIndex: try document.listTables().first?.index,
            row: 0,
            col: 0,
            text: "HGSET99"
        ) { table, row, col, text in
            var updated = document
            try updated.setCellText(table: table, row: row, col: col, text: text)
            document = updated
        }

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(live.setCellCalls.count, 1)
        XCTAssertEqual(live.setCellCalls.first?.0, 0)
        XCTAssertEqual(live.setCellCalls.first?.1, 0)
        XCTAssertEqual(live.setCellCalls.first?.2, 0)
        XCTAssertEqual(live.setCellCalls.first?.3, "HGSET99")
        XCTAssertTrue(document.hasUnsavedEdits)
        XCTAssertTrue(document.model.plainText.contains("HGSET99"))
        XCTAssertEqual(document.model.metadata.title, "허브")
        XCTAssertTrue(EngineClient.current is MockEngine)
    }

    func testFlowMapsHangyeolErrorWithoutFakeSuccess() {
        let outcome = TableCellEditFlow.commit(
            canEditCells: true,
            engineTableIndex: 0,
            row: 0,
            col: 0,
            text: "x"
        ) { _, _, _, _ in
            throw HangyeolError.engineFailed("CORRUPT")
        }
        XCTAssertEqual(outcome, .failed(.engineFailed("CORRUPT")))
        XCTAssertEqual(L10n.tableCellEditFailureTitle, "표 칸을 고치지 못했습니다")
        XCTAssertTrue(L10n.tableCellEditRetryHint.contains("다시 입력"))
    }

    func testDocumentWindowWiresSessionCellAPIs() throws {
        let window = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views/DocumentWindow.swift")
        let source = try String(contentsOf: window, encoding: .utf8)
        XCTAssertTrue(source.contains("document.session.canEditCells"))
        XCTAssertTrue(source.contains("document.listTables("))
        XCTAssertTrue(source.contains("updated.setCellText("))
        XCTAssertFalse(source.contains("tablesEditable: true"))
        XCTAssertFalse(source.contains("화면에만"))
    }

    func testViewsDoNotCallKitOrProcessWideCellAPIs() throws {
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
                source.contains("EngineClient.listTables"),
                "\(file.lastPathComponent) still uses EngineClient.listTables"
            )
            XCTAssertFalse(
                source.contains("EngineClient.setCellText"),
                "\(file.lastPathComponent) still uses EngineClient.setCellText"
            )
            XCTAssertFalse(
                source.contains("HangyeolKit.RealEngine"),
                "\(file.lastPathComponent) still uses HangyeolKit.RealEngine"
            )
            XCTAssertFalse(
                source.contains("kit.listTables"),
                "\(file.lastPathComponent) still uses kit.listTables"
            )
            XCTAssertFalse(
                source.contains("kit.setCellText"),
                "\(file.lastPathComponent) still uses kit.setCellText"
            )
        }
    }
}

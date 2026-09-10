import XCTest
@testable import Hangyeol

private final class ParagraphRecordingEngine: HangyeolLiveSession, @unchecked Sendable {
    var isOpen: Bool = true
    var listedTables: [TableInfo] = []
    var insertCalls: [(UInt32, UInt32, UInt32, String)] = []
    var deleteCalls: [(UInt32, UInt32, UInt32, UInt32)] = []
    var displayBlocks: [ContentBlock] = []
    var insertError: Error?
    var deleteError: Error?

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

    func listImages() throws -> [ImageInfo] { [] }

    func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        _ = table
        _ = row
        _ = col
        _ = text
    }

    func insertText(section: UInt32, paragraph: UInt32, charOffset: UInt32, text: String) throws {
        if let insertError {
            throw insertError
        }
        insertCalls.append((section, paragraph, charOffset, text))
    }

    func deleteRange(section: UInt32, paragraph: UInt32, charOffset: UInt32, count: UInt32) throws {
        if let deleteError {
            throw deleteError
        }
        deleteCalls.append((section, paragraph, charOffset, count))
    }
}

final class ParagraphEditUXTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EngineClient.useMockFlagKey)
        EngineClient.resetToDefault()
        super.tearDown()
    }

    func testReadOnlyWhenSessionCannotEditParagraphs() {
        let presentation = ParagraphEditPresentation.make(canEditParagraphs: false)
        XCTAssertFalse(presentation.usesField)
        XCTAssertNil(presentation.caption)
    }

    func testMockDocumentSessionStaysReadOnly() {
        EngineClient.resetToMock()
        let document = HangyeolDocument(model: MockEngine.sampleDocument())
        XCTAssertTrue(document.session.isUsingMock)
        XCTAssertFalse(document.session.canEditParagraphs)

        let presentation = ParagraphEditPresentation.make(
            canEditParagraphs: document.session.canEditParagraphs
        )
        XCTAssertFalse(presentation.usesField)
        XCTAssertNil(presentation.caption)

        let items = TableEditMapping.items(
            model: document.model,
            engineTables: [],
            canEditCells: document.session.canEditCells,
            canEditParagraphs: document.session.canEditParagraphs
        )
        let paragraphs = items.compactMap { item -> ParagraphEditSurface? in
            if case .paragraph(let surface) = item { return surface }
            return nil
        }
        XCTAssertFalse(paragraphs.isEmpty)
        XCTAssertTrue(paragraphs.allSatisfy { $0.editable == false })
    }

    func testLiveCaptionKeepsHubASmokeNote() {
        let presentation = ParagraphEditPresentation.make(canEditParagraphs: true)
        XCTAssertTrue(presentation.usesField)
        XCTAssertEqual(presentation.caption, L10n.paragraphEditLiveNote)
        XCTAssertTrue(L10n.paragraphEditLiveNote.contains("HGINS99"))
        XCTAssertTrue(L10n.paragraphEditLiveNote.contains("허브-A"))
        XCTAssertTrue(L10n.paragraphEditLiveNote.contains("HWPX"))
        XCTAssertFalse(L10n.paragraphEditLiveNote.localizedCaseInsensitiveContains("성공"))
        XCTAssertFalse(L10n.paragraphEditLiveNote.localizedCaseInsensitiveContains("Mock"))
        XCTAssertFalse(L10n.paragraphEditLiveNote.localizedCaseInsensitiveContains("XCFramework"))
    }

    func testParagraphAccessibilityUsesKoreanOrdinalAndVerb() {
        let editable = ParagraphEditPresentation.accessibilityLabel(
            ordinal: 0,
            text: "본문",
            editable: true
        )
        XCTAssertTrue(editable.contains("문단 1"))
        XCTAssertTrue(editable.contains("편집합니다"))
        XCTAssertTrue(editable.contains("본문"))

        let readOnly = ParagraphEditPresentation.accessibilityLabel(
            ordinal: 2,
            text: "한국어",
            editable: false
        )
        XCTAssertTrue(readOnly.contains("문단 3"))
        XCTAssertTrue(readOnly.contains("한국어"))
        XCTAssertFalse(readOnly.contains("편집합니다"))
    }

    func testEmptyParagraphAccessibilityUsesPlaceholder() {
        let label = ParagraphEditPresentation.accessibilityLabel(
            ordinal: 1,
            text: "  ",
            editable: true
        )
        XCTAssertTrue(label.contains("문단 2"))
        XCTAssertTrue(label.contains(L10n.paragraphEmpty))
        XCTAssertTrue(label.contains("편집합니다"))
    }

    func testDiffPrependsHubATokenAtOffsetZero() {
        let change = ParagraphEditDiff.change(from: "본문", to: "HGINS99본문")
        XCTAssertEqual(change?.charOffset, 0)
        XCTAssertEqual(change?.deleteCount, 0)
        XCTAssertEqual(change?.insertText, "HGINS99")
    }

    func testDiffDeletesPrefixScalars() {
        let change = ParagraphEditDiff.change(from: "HGINS99본문", to: "GINS99본문")
        XCTAssertEqual(change?.charOffset, 0)
        XCTAssertEqual(change?.deleteCount, 1)
        XCTAssertEqual(change?.insertText, "")
    }

    func testDiffReplacesMiddleHangul() {
        let change = ParagraphEditDiff.change(from: "가나다", to: "가XY다")
        XCTAssertEqual(change?.charOffset, 1)
        XCTAssertEqual(change?.deleteCount, 1)
        XCTAssertEqual(change?.insertText, "XY")
    }

    func testDiffUnchangedIsNil() {
        XCTAssertNil(ParagraphEditDiff.change(from: "본문", to: "본문"))
    }

    func testAddressMapsBodyOrdinalToSectionZeroParagraph() {
        let address = ParagraphEditMapping.address(bodyOrdinal: 0, engineTables: [])
        XCTAssertEqual(address?.section, 0)
        XCTAssertEqual(address?.paragraph, 0)

        let second = ParagraphEditMapping.address(bodyOrdinal: 2, engineTables: [])
        XCTAssertEqual(second?.section, 0)
        XCTAssertEqual(second?.paragraph, 2)
    }

    func testAddressUsesSharedTableSection() {
        let tables = [
            TableInfo(index: 0, section: 1, paragraph: 4, control: 0, rows: 2, cols: 2),
            TableInfo(index: 1, section: 1, paragraph: 8, control: 0, rows: 1, cols: 1)
        ]
        let address = ParagraphEditMapping.address(bodyOrdinal: 0, engineTables: tables)
        XCTAssertEqual(address?.section, 1)
        XCTAssertEqual(address?.paragraph, 0)
    }

    func testAddressDoesNotGuessWhenTablesSpanSections() {
        let tables = [
            TableInfo(index: 0, section: 0, paragraph: 1, control: 0, rows: 1, cols: 1),
            TableInfo(index: 1, section: 2, paragraph: 0, control: 0, rows: 1, cols: 1)
        ]
        let address = ParagraphEditMapping.address(bodyOrdinal: 1, engineTables: tables)
        XCTAssertEqual(address?.section, 0)
        XCTAssertEqual(address?.paragraph, 1)
    }

    func testFlattenedBodyParagraphsGetEngineAddressNotCellSlots() {
        let lines = ["본문", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        let model = DocumentModel(
            metadata: DocumentMetadata(title: "허브-A", sourceType: .hwpx),
            blocks: lines.map { .paragraph(ParagraphBlock(text: $0)) }
        )
        let info = TableInfo(index: 0, section: 0, paragraph: 0, control: 0, rows: 3, cols: 3)
        let items = TableEditMapping.items(
            model: model,
            engineTables: [info],
            canEditCells: true,
            canEditParagraphs: true
        )
        XCTAssertEqual(items.count, 2)
        guard case .paragraph(let body) = items[0] else {
            return XCTFail("expected leading body paragraph")
        }
        XCTAssertEqual(body.plainText, "본문")
        XCTAssertEqual(body.section, 0)
        XCTAssertEqual(body.paragraphIndex, 0)
        XCTAssertTrue(body.editable)
        guard case .table(let surface) = items[1] else {
            return XCTFail("expected synthesized table")
        }
        XCTAssertTrue(surface.editable)
        XCTAssertEqual(surface.table.rows[0].cells[0].text, "1")
    }

    func testCellLinesAreNotParagraphEditTargetsWhenTablesUnknown() {
        let model = DocumentModel(
            metadata: DocumentMetadata(title: "허브-A", sourceType: .hwpx),
            blocks: [
                .paragraph(ParagraphBlock(text: "본문")),
                .paragraph(ParagraphBlock(text: "셀"))
            ]
        )
        let items = TableEditMapping.items(
            model: model,
            engineTables: [],
            canEditCells: false,
            canEditParagraphs: true
        )
        XCTAssertEqual(items.count, 2)
        guard case .paragraph(let first) = items[0],
              case .paragraph(let second) = items[1] else {
            return XCTFail("expected two body paragraphs when no listTables grids")
        }
        XCTAssertEqual(first.paragraphIndex, 0)
        XCTAssertEqual(second.paragraphIndex, 1)
        XCTAssertTrue(first.editable && second.editable)
    }

    func testFlowSkipsMockWithoutCallingSession() {
        var insertCalled = false
        var deleteCalled = false
        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: false,
            section: 0,
            paragraph: 0,
            oldText: "본문",
            newText: "HGINS99본문",
            insert: { _, _, _, _ in insertCalled = true },
            delete: { _, _, _, _ in deleteCalled = true }
        )
        XCTAssertEqual(outcome, .skippedUnavailable)
        XCTAssertFalse(insertCalled)
        XCTAssertFalse(deleteCalled)
    }

    func testFlowSkipsUnmappedAddress() {
        var called = false
        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: true,
            section: nil,
            paragraph: nil,
            oldText: "본문",
            newText: "HGINS99본문",
            insert: { _, _, _, _ in called = true },
            delete: { _, _, _, _ in called = true }
        )
        XCTAssertEqual(outcome, .skippedUnmapped)
        XCTAssertFalse(called)
    }

    func testFlowSkipsUnchangedText() {
        var called = false
        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: true,
            section: 0,
            paragraph: 0,
            oldText: "본문",
            newText: "본문",
            insert: { _, _, _, _ in called = true },
            delete: { _, _, _, _ in called = true }
        )
        XCTAssertEqual(outcome, .skippedUnchanged)
        XCTAssertFalse(called)
    }

    func testFlowCallsDocumentInsertTextAndRefreshesModel() throws {
        let live = ParagraphRecordingEngine()
        live.displayBlocks = [.paragraph(ParagraphBlock(text: "HGINS99본문"))]
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "허브", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: "본문"))]
            ),
            session: DocumentSession(engine: live)
        )
        XCTAssertTrue(document.session.canEditParagraphs)
        XCTAssertFalse(document.hasUnsavedEdits)

        EngineClient.current = MockEngine()

        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: document.session.canEditParagraphs,
            section: 0,
            paragraph: 0,
            oldText: "본문",
            newText: "HGINS99본문",
            insert: { section, paragraph, offset, text in
                var updated = document
                try updated.insertText(
                    section: section,
                    paragraph: paragraph,
                    charOffset: offset,
                    text: text
                )
                document = updated
            },
            delete: { section, paragraph, offset, count in
                var updated = document
                try updated.deleteRange(
                    section: section,
                    paragraph: paragraph,
                    charOffset: offset,
                    count: count
                )
                document = updated
            }
        )

        XCTAssertEqual(outcome, .updated)
        XCTAssertTrue(live.deleteCalls.isEmpty)
        XCTAssertEqual(live.insertCalls.count, 1)
        XCTAssertEqual(live.insertCalls.first?.0, 0)
        XCTAssertEqual(live.insertCalls.first?.1, 0)
        XCTAssertEqual(live.insertCalls.first?.2, 0)
        XCTAssertEqual(live.insertCalls.first?.3, "HGINS99")
        XCTAssertTrue(document.hasUnsavedEdits)
        XCTAssertTrue(document.model.plainText.contains("HGINS99"))
        XCTAssertEqual(document.model.metadata.title, "허브")
        XCTAssertTrue(EngineClient.current is MockEngine)
    }

    func testFlowCallsDocumentDeleteRangeForPrefixRemoval() throws {
        let live = ParagraphRecordingEngine()
        live.displayBlocks = [.paragraph(ParagraphBlock(text: "GINS99본문"))]
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "허브", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: "HGINS99본문"))]
            ),
            session: DocumentSession(engine: live)
        )

        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: document.session.canEditParagraphs,
            section: 0,
            paragraph: 0,
            oldText: "HGINS99본문",
            newText: "GINS99본문",
            insert: { section, paragraph, offset, text in
                var updated = document
                try updated.insertText(
                    section: section,
                    paragraph: paragraph,
                    charOffset: offset,
                    text: text
                )
                document = updated
            },
            delete: { section, paragraph, offset, count in
                var updated = document
                try updated.deleteRange(
                    section: section,
                    paragraph: paragraph,
                    charOffset: offset,
                    count: count
                )
                document = updated
            }
        )

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(live.deleteCalls.count, 1)
        XCTAssertEqual(live.deleteCalls.first?.0, 0)
        XCTAssertEqual(live.deleteCalls.first?.1, 0)
        XCTAssertEqual(live.deleteCalls.first?.2, 0)
        XCTAssertEqual(live.deleteCalls.first?.3, 1)
        XCTAssertTrue(live.insertCalls.isEmpty)
        XCTAssertTrue(document.hasUnsavedEdits)
    }

    func testFlowDeletesThenInsertsForMiddleReplace() {
        var inserts: [(UInt32, UInt32, UInt32, String)] = []
        var deletes: [(UInt32, UInt32, UInt32, UInt32)] = []
        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: true,
            section: 0,
            paragraph: 2,
            oldText: "가나다",
            newText: "가XY다",
            insert: { inserts.append(($0, $1, $2, $3)) },
            delete: { deletes.append(($0, $1, $2, $3)) }
        )
        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(deletes.count, 1)
        XCTAssertEqual(deletes.first?.0, 0)
        XCTAssertEqual(deletes.first?.1, 2)
        XCTAssertEqual(deletes.first?.2, 1)
        XCTAssertEqual(deletes.first?.3, 1)
        XCTAssertEqual(inserts.count, 1)
        XCTAssertEqual(inserts.first?.0, 0)
        XCTAssertEqual(inserts.first?.1, 2)
        XCTAssertEqual(inserts.first?.2, 1)
        XCTAssertEqual(inserts.first?.3, "XY")
    }

    func testFlowMapsHangyeolErrorWithoutFakeSuccess() {
        let outcome = ParagraphEditFlow.commit(
            canEditParagraphs: true,
            section: 0,
            paragraph: 0,
            oldText: "본문",
            newText: "x",
            insert: { _, _, _, _ in
                throw HangyeolError.engineFailed("CORRUPT")
            },
            delete: { _, _, _, _ in
                throw HangyeolError.engineFailed("CORRUPT")
            }
        )
        XCTAssertEqual(outcome, .failed(.engineFailed("CORRUPT")))
        XCTAssertEqual(L10n.paragraphEditFailureTitle, "문단을 고치지 못했습니다")
        XCTAssertTrue(L10n.paragraphEditRetryHint.contains("다시 입력"))
        XCTAssertTrue(L10n.paragraphEditFailureTitle.contains("고치지"))
    }

    func testDocumentWindowWiresSessionParagraphAPIs() throws {
        let window = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views/DocumentWindow.swift")
        let source = try String(contentsOf: window, encoding: .utf8)
        XCTAssertTrue(source.contains("document.session.canEditParagraphs"))
        XCTAssertTrue(source.contains("updated.insertText("))
        XCTAssertTrue(source.contains("updated.deleteRange("))
        XCTAssertFalse(source.contains("화면에만"))
    }

    func testViewsDoNotCallKitOrProcessWideParagraphAPIs() throws {
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
                source.contains("EngineClient.insertText"),
                "\(file.lastPathComponent) still uses EngineClient.insertText"
            )
            XCTAssertFalse(
                source.contains("EngineClient.deleteRange"),
                "\(file.lastPathComponent) still uses EngineClient.deleteRange"
            )
            XCTAssertFalse(
                source.contains("HangyeolKit.RealEngine"),
                "\(file.lastPathComponent) still uses HangyeolKit.RealEngine"
            )
            XCTAssertFalse(
                source.contains("kit.insertText"),
                "\(file.lastPathComponent) still uses kit.insertText"
            )
            XCTAssertFalse(
                source.contains("kit.deleteRange"),
                "\(file.lastPathComponent) still uses kit.deleteRange"
            )
        }
    }
}

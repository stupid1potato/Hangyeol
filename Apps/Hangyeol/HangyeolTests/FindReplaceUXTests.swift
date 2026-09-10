import XCTest
@testable import Hangyeol

private final class RecordingLiveEngine: HangyeolLiveSession, @unchecked Sendable {
    var isOpen: Bool = true
    var replaceCalls: [(String, String)] = []
    var replaceResult: Int = 2
    var displayPlainText: String = "replaced"

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
        replaceCalls.append((find, replace))
        return replaceResult
    }

    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: title, sourceType: type),
            blocks: [.paragraph(ParagraphBlock(text: displayPlainText))]
        )
    }

    func saveHwpx(to path: String) throws {
        try Data().write(to: URL(fileURLWithPath: path))
    }

    func listTables() throws -> [TableInfo] { [] }

    func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        _ = table
        _ = row
        _ = col
        _ = text
    }
}

final class FindReplaceUXTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EngineClient.useMockFlagKey)
        EngineClient.resetToDefault()
        super.tearDown()
    }

    func testStubWhenSessionCannotReplace() {
        let presentation = FindReplacePresentation.make(
            canReplace: false,
            query: "1",
            lastReplacementCount: nil
        )
        XCTAssertFalse(presentation.isReplaceEnabled)
        XCTAssertFalse(presentation.isFindNextEnabled)
        XCTAssertEqual(presentation.statusCaption, L10n.findStubNote)
        XCTAssertFalse(presentation.shouldFocusStatus)
        XCTAssertFalse(presentation.statusCaption.localizedCaseInsensitiveContains("성공"))
        XCTAssertFalse(L10n.findStubNote.localizedCaseInsensitiveContains("Mock"))
        XCTAssertFalse(L10n.findStubNote.localizedCaseInsensitiveContains("XCFramework"))
    }

    func testMockDocumentSessionDisablesReplace() {
        EngineClient.resetToMock()
        let document = HangyeolDocument(model: MockEngine.sampleDocument())
        XCTAssertTrue(document.session.isUsingMock)
        XCTAssertFalse(document.session.canReplace)

        let presentation = FindReplacePresentation.make(
            canReplace: document.session.canReplace,
            query: "1",
            lastReplacementCount: nil
        )
        XCTAssertFalse(presentation.isReplaceEnabled)
        XCTAssertEqual(presentation.statusCaption, L10n.findStubNote)
    }

    func testLiveCaptionKeepsHubASmokeNoteUntilReplace() {
        let presentation = FindReplacePresentation.make(
            canReplace: true,
            query: "1",
            lastReplacementCount: nil
        )
        XCTAssertTrue(presentation.isReplaceEnabled)
        XCTAssertEqual(presentation.statusCaption, L10n.findLiveNote)
        XCTAssertTrue(L10n.findLiveNote.contains("HGPOC99"))
        XCTAssertTrue(L10n.findLiveNote.contains("허브-A"))
        XCTAssertTrue(L10n.findLiveNote.contains("HWPX"))
    }

    func testEmptyQueryDisablesReplaceEvenWhenSessionIsLive() {
        let presentation = FindReplacePresentation.make(
            canReplace: true,
            query: "",
            lastReplacementCount: nil
        )
        XCTAssertFalse(presentation.isReplaceEnabled)
        XCTAssertEqual(presentation.statusCaption, L10n.findLiveNote)
    }

    func testKoreanCountCaptionAndFocusAfterReplace() {
        XCTAssertEqual(L10n.replacedCount(0), "바꿀 곳이 없습니다.")
        XCTAssertEqual(L10n.replacedCount(1), "1곳을 바꿨습니다.")
        XCTAssertEqual(L10n.replacedCount(3), "3곳을 바꿨습니다.")

        let none = FindReplacePresentation.make(
            canReplace: true,
            query: "없음",
            lastReplacementCount: 0,
            statusFocusToken: 1
        )
        XCTAssertEqual(none.statusCaption, "바꿀 곳이 없습니다.")
        XCTAssertTrue(none.shouldFocusStatus)

        let some = FindReplacePresentation.make(
            canReplace: true,
            query: "1",
            lastReplacementCount: 2,
            statusFocusToken: 2
        )
        XCTAssertEqual(some.statusCaption, "2곳을 바꿨습니다.")
        XCTAssertTrue(some.shouldFocusStatus)
    }

    func testVerbObjectButtonCopy() {
        XCTAssertEqual(L10n.findNext, "다음 찾기")
        XCTAssertEqual(L10n.replace, "모두 바꾸기")
        XCTAssertEqual(L10n.find, "찾기…")
    }

    func testFlowSkipsMockWithoutCallingSession() {
        var called = false
        let outcome = FindReplaceFlow.replace(
            canReplace: false,
            find: "1",
            replace: "HGPOC99"
        ) { _, _ in
            called = true
            return 99
        }
        XCTAssertEqual(outcome, .skippedUnavailable)
        XCTAssertFalse(called)
    }

    func testFlowSkipsEmptyQuery() {
        var called = false
        let outcome = FindReplaceFlow.replace(
            canReplace: true,
            find: "",
            replace: "HGPOC99"
        ) { _, _ in
            called = true
            return 1
        }
        XCTAssertEqual(outcome, .skippedEmptyQuery)
        XCTAssertFalse(called)
    }

    func testFlowReturnsSessionCountAndRefreshesBoundDocument() throws {
        let live = RecordingLiveEngine()
        live.replaceResult = 4
        live.displayPlainText = "HGPOC99"
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "허브", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: "1"))]
            ),
            session: DocumentSession(engine: live)
        )
        XCTAssertTrue(document.session.canReplace)
        XCTAssertFalse(document.hasUnsavedEdits)

        EngineClient.current = MockEngine()

        let outcome = FindReplaceFlow.replace(
            canReplace: document.session.canReplace,
            find: "1",
            replace: "HGPOC99"
        ) { find, replacement in
            var updated = document
            let count = try updated.replaceText(find: find, replace: replacement)
            document = updated
            return count
        }

        XCTAssertEqual(outcome, .replaced(4))
        XCTAssertEqual(live.replaceCalls.count, 1)
        XCTAssertEqual(live.replaceCalls.first?.0, "1")
        XCTAssertEqual(live.replaceCalls.first?.1, "HGPOC99")
        XCTAssertEqual(document.model.plainText, "HGPOC99")
        XCTAssertEqual(document.model.metadata.title, "허브")
        XCTAssertTrue(document.hasUnsavedEdits)
        XCTAssertTrue(EngineClient.current is MockEngine)
    }

    func testFlowMapsHangyeolError() {
        let outcome = FindReplaceFlow.replace(
            canReplace: true,
            find: "1",
            replace: "x"
        ) { _, _ in
            throw HangyeolError.saveRejected
        }
        XCTAssertEqual(outcome, .failed(.saveRejected))
    }

    func testViewsDoNotCallProcessWideEngineClientReplace() throws {
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
                source.contains("EngineClient.liveSession"),
                "\(file.lastPathComponent) still uses EngineClient.liveSession"
            )
            XCTAssertFalse(
                source.contains("EngineClient.replaceText"),
                "\(file.lastPathComponent) still uses EngineClient.replaceText"
            )
            XCTAssertFalse(
                source.contains("EngineClient.refreshDisplayModel"),
                "\(file.lastPathComponent) still uses EngineClient.refreshDisplayModel"
            )
        }
    }
}

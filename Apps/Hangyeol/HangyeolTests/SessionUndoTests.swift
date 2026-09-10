import XCTest
@testable import Hangyeol

/// Stateful live engine: mutations change `body` / `cells`, and undo peeks + snapshots work.
private final class SnapshotLiveEngine: HangyeolLiveSession, @unchecked Sendable {
    var isOpen: Bool = true
    var body: String = "원본"
    var cells: [String: String] = [:]
    var shouldFail = false
    var captureCount = 0
    var insertCalls: [(UInt32, UInt32, UInt32, String)] = []
    var deleteCalls: [(UInt32, UInt32, UInt32, UInt32)] = []
    var setCellCalls: [(UInt32, UInt32, UInt32, String)] = []
    var replaceCalls: [(String, String)] = []

    private struct Payload: Codable {
        var body: String
        var cells: [String: String]
    }

    private func failIfNeeded() throws {
        if shouldFail {
            throw HangyeolError.engineFailed("fail")
        }
    }

    private static func cellKey(table: UInt32, row: UInt32, col: UInt32) -> String {
        "\(table)-\(row)-\(col)"
    }

    func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        body = String(data: data, encoding: .utf8) ?? ""
        cells = [:]
        return try displayModel(type: type, title: "live")
    }

    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        Data("live-ir|\(type.rawValue)|\(model.plainText)".utf8)
    }

    func replaceText(find: String, replace: String) throws -> Int {
        try failIfNeeded()
        replaceCalls.append((find, replace))
        guard !find.isEmpty else { return 0 }
        let matches = body.components(separatedBy: find).count - 1
        body = body.replacingOccurrences(of: find, with: replace)
        for key in cells.keys {
            cells[key] = cells[key]?.replacingOccurrences(of: find, with: replace)
        }
        return max(matches, 0)
    }

    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        var blocks: [ContentBlock] = [.paragraph(ParagraphBlock(text: body))]
        for key in cells.keys.sorted() {
            guard let value = cells[key], !value.isEmpty else { continue }
            blocks.append(.paragraph(ParagraphBlock(text: "\(key)=\(value)")))
        }
        return DocumentModel(
            metadata: DocumentMetadata(title: title, sourceType: type),
            blocks: blocks
        )
    }

    func saveHwpx(to path: String) throws {
        try Data("live-hwpx".utf8).write(to: URL(fileURLWithPath: path))
    }

    func listTables() throws -> [TableInfo] { [] }

    func listImages() throws -> [ImageInfo] { [] }

    func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        try failIfNeeded()
        setCellCalls.append((table, row, col, text))
        cells[Self.cellKey(table: table, row: row, col: col)] = text
    }

    func insertText(section: UInt32, paragraph: UInt32, charOffset: UInt32, text: String) throws {
        try failIfNeeded()
        insertCalls.append((section, paragraph, charOffset, text))
        _ = paragraph
        _ = section
        body = Self.spliced(body, offset: Int(charOffset), deleting: 0, inserting: text)
    }

    func deleteRange(section: UInt32, paragraph: UInt32, charOffset: UInt32, count: UInt32) throws {
        try failIfNeeded()
        deleteCalls.append((section, paragraph, charOffset, count))
        _ = paragraph
        _ = section
        body = Self.spliced(body, offset: Int(charOffset), deleting: Int(count), inserting: "")
    }

    func textInRange(
        section: UInt32,
        paragraph: UInt32,
        charOffset: UInt32,
        count: UInt32
    ) throws -> String {
        _ = section
        _ = paragraph
        let scalars = Array(body.unicodeScalars)
        let start = Int(charOffset)
        let end = min(start + Int(count), scalars.count)
        guard start >= 0, start <= scalars.count, start <= end else { return "" }
        return String(String.UnicodeScalarView(scalars[start..<end]))
    }

    func cellText(table: UInt32, row: UInt32, col: UInt32) throws -> String {
        cells[Self.cellKey(table: table, row: row, col: col)] ?? ""
    }

    func captureUndoState() throws -> Data {
        captureCount += 1
        return try JSONEncoder().encode(Payload(body: body, cells: cells))
    }

    func restoreUndoState(_ data: Data) throws {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        body = payload.body
        cells = payload.cells
    }

    private static func spliced(
        _ text: String,
        offset: Int,
        deleting: Int,
        inserting: String
    ) -> String {
        var scalars = Array(text.unicodeScalars)
        let start = max(0, min(offset, scalars.count))
        let end = max(start, min(start + max(0, deleting), scalars.count))
        scalars.removeSubrange(start..<end)
        scalars.insert(contentsOf: inserting.unicodeScalars, at: start)
        return String(String.UnicodeScalarView(scalars))
    }
}

private final class DefaultPeekLiveEngine: HangyeolLiveSession, @unchecked Sendable {
    var isOpen: Bool = true
    var replaceCount = 0

    func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: "live", sourceType: type),
            blocks: [.paragraph(ParagraphBlock(text: String(data: data, encoding: .utf8) ?? ""))]
        )
    }

    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        Data("live-ir|\(type.rawValue)|\(model.plainText)".utf8)
    }

    func replaceText(find: String, replace: String) throws -> Int {
        _ = find
        _ = replace
        replaceCount += 1
        return 1
    }

    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: title, sourceType: type),
            blocks: [.paragraph(ParagraphBlock(text: "replaced"))]
        )
    }

    func saveHwpx(to path: String) throws {
        try Data().write(to: URL(fileURLWithPath: path))
    }

    func listTables() throws -> [TableInfo] { [] }

    func listImages() throws -> [ImageInfo] { [] }

    func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        _ = table
        _ = row
        _ = col
        _ = text
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

final class SessionUndoTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EngineClient.useMockFlagKey)
        EngineClient.resetToDefault()
        super.tearDown()
    }

    private func makeDocument(
        engine: SnapshotLiveEngine,
        undo: UndoManager
    ) -> HangyeolDocument {
        undo.groupsByEvent = false
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "제목", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: engine.body))]
            ),
            session: DocumentSession(engine: engine)
        )
        document.session.attachUndoManager(undo)
        return document
    }

    func testReplaceUndoRestoresDisplayModelAndRedoReapplies() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)

        let count = try document.replaceText(find: "원본", replace: "새글")
        XCTAssertEqual(count, 1)
        XCTAssertEqual(live.body, "새글")
        XCTAssertEqual(document.model.plainText, "새글")
        XCTAssertTrue(document.hasUnsavedEdits)
        XCTAssertTrue(undo.canUndo)
        XCTAssertFalse(undo.canRedo)
        XCTAssertEqual(live.captureCount, 1)

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.body, "원본")
        XCTAssertEqual(document.model.plainText, "원본")
        XCTAssertEqual(document.model.metadata.title, "제목")
        XCTAssertFalse(document.hasUnsavedEdits)
        XCTAssertFalse(undo.canUndo)
        XCTAssertTrue(undo.canRedo)
        XCTAssertEqual(document.session.undoGeneration, 1)

        undo.redo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.body, "새글")
        XCTAssertEqual(document.model.plainText, "새글")
        XCTAssertTrue(document.hasUnsavedEdits)
        XCTAssertTrue(undo.canUndo)
        XCTAssertFalse(undo.canRedo)
        XCTAssertEqual(document.session.undoGeneration, 2)
    }

    func testInsertUndoUsesInverseDeleteRange() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)

        try document.insertText(section: 0, paragraph: 0, charOffset: 0, text: "앞")
        XCTAssertEqual(live.body, "앞원본")
        XCTAssertEqual(document.model.plainText, "앞원본")
        XCTAssertEqual(live.insertCalls.count, 1)
        XCTAssertTrue(undo.canUndo)

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.deleteCalls.count, 1)
        XCTAssertEqual(live.deleteCalls[0].0, 0)
        XCTAssertEqual(live.deleteCalls[0].1, 0)
        XCTAssertEqual(live.deleteCalls[0].2, 0)
        XCTAssertEqual(live.deleteCalls[0].3, 1)
        XCTAssertEqual(live.body, "원본")
        XCTAssertEqual(document.model.plainText, "원본")
        XCTAssertFalse(document.hasUnsavedEdits)

        undo.redo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.insertCalls.count, 2)
        XCTAssertEqual(live.insertCalls[1].3, "앞")
        XCTAssertEqual(live.body, "앞원본")
        XCTAssertEqual(document.model.plainText, "앞원본")
        XCTAssertTrue(document.hasUnsavedEdits)
    }

    func testDeleteRangeUndoReinsertsCapturedText() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)

        try document.deleteRange(section: 0, paragraph: 0, charOffset: 0, count: 1)
        XCTAssertEqual(live.body, "본")
        XCTAssertEqual(document.model.plainText, "본")

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.insertCalls.count, 1)
        XCTAssertEqual(live.insertCalls[0].3, "원")
        XCTAssertEqual(live.body, "원본")
        XCTAssertEqual(document.model.plainText, "원본")
        XCTAssertFalse(document.hasUnsavedEdits)

        undo.redo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.body, "본")
        XCTAssertEqual(document.model.plainText, "본")
    }

    func testSetCellTextUndoRestoresPriorCell() throws {
        let live = SnapshotLiveEngine()
        live.cells["0-0-1"] = "이전"
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)
        document.model = try document.session.displayModel(type: .hwpx, title: "제목")

        try document.setCellText(table: 0, row: 0, col: 1, text: "새")
        XCTAssertEqual(live.cells["0-0-1"], "새")
        XCTAssertTrue(document.model.plainText.contains("0-0-1=새"))

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.cells["0-0-1"], "이전")
        XCTAssertTrue(document.model.plainText.contains("0-0-1=이전"))
        XCTAssertFalse(document.hasUnsavedEdits)

        undo.redo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.cells["0-0-1"], "새")
        XCTAssertTrue(document.model.plainText.contains("0-0-1=새"))
        XCTAssertTrue(document.hasUnsavedEdits)
    }

    func testSequentialEditsUndoInReverseOrder() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)

        try document.insertText(section: 0, paragraph: 0, charOffset: 1, text: "X")
        _ = try document.replaceText(find: "원X본", replace: "완료")
        XCTAssertEqual(live.body, "완료")

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.body, "원X본")

        undo.undo()
        document.refreshAfterUndoRedo()
        XCTAssertEqual(live.body, "원본")
        XCTAssertFalse(document.hasUnsavedEdits)
    }

    func testFailedEditDoesNotRegisterUndo() {
        let live = SnapshotLiveEngine()
        live.shouldFail = true
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)

        XCTAssertThrowsError(try document.replaceText(find: "원본", replace: "새"))
        XCTAssertThrowsError(try document.setCellText(table: 0, row: 0, col: 0, text: "x"))
        XCTAssertThrowsError(try document.insertText(section: 0, paragraph: 0, charOffset: 0, text: "x"))
        XCTAssertThrowsError(try document.deleteRange(section: 0, paragraph: 0, charOffset: 0, count: 1))
        XCTAssertFalse(undo.canUndo)
        XCTAssertFalse(document.hasUnsavedEdits)
        XCTAssertEqual(document.session.undoGeneration, 0)
        XCTAssertEqual(live.body, "원본")
    }

    func testMockEditsDoNotRegisterSpuriousUndos() {
        let undo = UndoManager()
        undo.groupsByEvent = false
        var document = HangyeolDocument(
            model: MockEngine.sampleDocument(),
            session: DocumentSession(engine: MockEngine())
        )
        document.session.attachUndoManager(undo)

        XCTAssertThrowsError(try document.replaceText(find: "a", replace: "b"))
        XCTAssertThrowsError(try document.setCellText(table: 0, row: 0, col: 0, text: "x"))
        XCTAssertThrowsError(try document.insertText(section: 0, paragraph: 0, charOffset: 0, text: "x"))
        XCTAssertThrowsError(try document.deleteRange(section: 0, paragraph: 0, charOffset: 0, count: 1))
        XCTAssertFalse(undo.canUndo)
        XCTAssertFalse(undo.canRedo)
        XCTAssertFalse(document.hasUnsavedEdits)
        XCTAssertFalse(document.session.hasUndoableEdits)
        XCTAssertEqual(document.session.undoGeneration, 0)
    }

    func testWithoutUndoManagerCaptureIsSkipped() throws {
        let live = SnapshotLiveEngine()
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "제목", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: live.body))]
            ),
            session: DocumentSession(engine: live)
        )
        XCTAssertNil(document.session.undoManager)

        _ = try document.replaceText(find: "원본", replace: "새")
        try document.insertText(section: 0, paragraph: 0, charOffset: 0, text: "Z")
        XCTAssertEqual(live.captureCount, 0)
        XCTAssertFalse(document.session.hasUndoableEdits)
    }

    func testDefaultLiveReplaceDoesNotInventSnapshotUndo() throws {
        let live = DefaultPeekLiveEngine()
        let undo = UndoManager()
        undo.groupsByEvent = false
        var document = HangyeolDocument(
            model: DocumentModel(
                metadata: DocumentMetadata(title: "제목", sourceType: .hwpx),
                blocks: [.paragraph(ParagraphBlock(text: "원본"))]
            ),
            session: DocumentSession(engine: live)
        )
        document.session.attachUndoManager(undo)

        _ = try document.replaceText(find: "원본", replace: "새")
        XCTAssertEqual(live.replaceCount, 1)
        XCTAssertFalse(undo.canUndo)
        XCTAssertTrue(document.hasUnsavedEdits)
    }

    func testOpenClearsRegisteredUndos() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)
        _ = try document.replaceText(find: "원본", replace: "새글")
        XCTAssertTrue(undo.canUndo)

        _ = try document.session.open(data: Data("다시".utf8), type: .hwpx)
        XCTAssertFalse(undo.canUndo)
        XCTAssertFalse(document.session.hasUndoableEdits)
        XCTAssertEqual(live.body, "다시")
    }

    func testZeroReplacementsDoNotRegisterUndo() throws {
        let live = SnapshotLiveEngine()
        let undo = UndoManager()
        var document = makeDocument(engine: live, undo: undo)
        let count = try document.replaceText(find: "없는값", replace: "x")
        XCTAssertEqual(count, 0)
        XCTAssertFalse(undo.canUndo)
        XCTAssertEqual(live.body, "원본")
    }

    func testDocumentWindowOnlyAttachesSessionUndoHook() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views/DocumentWindow.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(source.contains("hangyeolSessionUndo(document:"))
        XCTAssertFalse(source.contains("registerUndo"))
        XCTAssertFalse(source.contains("NSUndoManager"))
        XCTAssertFalse(source.contains("HangyeolKit"))
    }

    func testEditMenuIsNotReplacedByAppCommands() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/App/HangyeolCommands.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(source.contains("replacing: .undoRedo"))
        XCTAssertFalse(source.contains("CommandGroup(replacing: .textEditing)"))
    }
}

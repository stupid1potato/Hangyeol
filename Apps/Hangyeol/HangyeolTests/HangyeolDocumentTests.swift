import UniformTypeIdentifiers
import XCTest
@testable import Hangyeol

final class HangyeolDocumentTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EngineClient.useMockFlagKey)
        EngineClient.resetToDefault()
        super.tearDown()
    }

    func testReadableTypesIncludeHwpxAndHwp() {
        XCTAssertTrue(HangyeolDocument.readableContentTypes.contains(.hangyeolHwpx))
        XCTAssertTrue(HangyeolDocument.readableContentTypes.contains(.hangyeolHwp))
        XCTAssertEqual(
            HangyeolDocument.readableContentTypes.map(\.identifier),
            [UTType.hangyeolHwpx.identifier, UTType.hangyeolHwp.identifier]
        )
    }

    func testWritableTypeIsHwpxByDefault() {
        XCTAssertEqual(HangyeolDocument.writableContentTypes, [.hangyeolHwpx])
    }

    func testNewDocumentIsEmpty() {
        XCTAssertTrue(HangyeolDocument().model.isEmpty)
    }

    func testUTTypeIdentifiers() {
        XCTAssertEqual(UTType.hangyeolHwpx.identifier, "org.hangyeol.hwpx")
        XCTAssertEqual(UTType.hangyeolHwp.identifier, "org.hangyeol.hwp")
    }

    func testEngineClientResetToMockStillOpensSample() throws {
        EngineClient.resetToMock()
        XCTAssertTrue(EngineClient.current is MockEngine)
        let model = try EngineClient.current.open(data: Data("sample".utf8), type: .hwpx)
        XCTAssertFalse(model.isEmpty)
    }

    func testNewDocumentsEachBindASession() {
        EngineClient.resetToMock()
        let a = HangyeolDocument()
        let b = HangyeolDocument()
        XCTAssertFalse(a.session === b.session)
    }

    func testCellApisOnUntitledMockDocumentThrowNotYetImplemented() {
        EngineClient.resetToMock()
        var document = HangyeolDocument()
        XCTAssertFalse(document.session.canEditCells)
        XCTAssertThrowsError(try document.listTables()) { error in
            guard case HangyeolError.notYetImplemented = error else {
                return XCTFail("expected notYetImplemented, got \(error)")
            }
        }
        XCTAssertThrowsError(try document.setCellText(table: 0, row: 0, col: 0, text: "x")) { error in
            guard case HangyeolError.notYetImplemented = error else {
                return XCTFail("expected notYetImplemented, got \(error)")
            }
        }
        XCTAssertFalse(document.hasUnsavedEdits)
    }

    func testParagraphApisOnUntitledMockDocumentThrowNotYetImplemented() {
        EngineClient.resetToMock()
        var document = HangyeolDocument()
        XCTAssertFalse(document.session.canEdit)
        XCTAssertFalse(document.session.canEditParagraphs)
        XCTAssertThrowsError(try document.insertText(section: 0, paragraph: 0, charOffset: 0, text: "x")) { error in
            guard case HangyeolError.notYetImplemented = error else {
                return XCTFail("expected notYetImplemented, got \(error)")
            }
        }
        XCTAssertThrowsError(try document.deleteRange(section: 0, paragraph: 0, charOffset: 0, count: 1)) { error in
            guard case HangyeolError.notYetImplemented = error else {
                return XCTFail("expected notYetImplemented, got \(error)")
            }
        }
        XCTAssertFalse(document.hasUnsavedEdits)
    }

    func testOpenConfigurationDoesNotUseProcessSingleton() throws {
        EngineClient.resetToMock()
        var snapshot = MockEngine.sampleDocument()
        snapshot.metadata.title = ""
        let payload = try JSONEncoder().encode(snapshot)
        EngineClient.current = KitRealEngine()

        let wrapper = FileWrapper(regularFileWithContents: payload)
        wrapper.filename = "singleton-clobber.hwpx"
        let document = try HangyeolDocument(
            configuration: HangyeolDocument.ReadConfiguration(
                contentType: .hangyeolHwpx,
                file: wrapper
            )
        )
        XCTAssertTrue(document.session.isUsingMock)
        XCTAssertFalse(document.model.isEmpty)
        XCTAssertEqual(document.model.metadata.title, "singleton-clobber")
    }
}

import UniformTypeIdentifiers
import XCTest
@testable import Hangyeol

final class HangyeolDocumentTests: XCTestCase {
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
}

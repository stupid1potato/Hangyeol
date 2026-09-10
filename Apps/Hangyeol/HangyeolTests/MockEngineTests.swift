import XCTest
@testable import Hangyeol

final class MockEngineTests: XCTestCase {
    private let engine = MockEngine()

    func testEmptyDataReturnsEmptyModel() throws {
        let model = try engine.open(data: Data(), type: .hwpx)
        XCTAssertTrue(model.isEmpty)
    }

    func testNonEmptyUnknownDataReturnsKoreanParagraphsAndTable() throws {
        let model = try engine.open(data: Data("not-json".utf8), type: .hwpx)
        let paragraphs = model.blocks.compactMap { block -> String? in
            if case .paragraph(let paragraph) = block {
                return paragraph.plainText
            }
            return nil
        }

        XCTAssertTrue(paragraphs.contains(where: { $0.contains("한결") }))
        XCTAssertTrue(paragraphs.contains(where: { $0.contains("환영") }))

        let tables = model.blocks.compactMap { block -> TableBlock? in
            if case .table(let table) = block {
                return table
            }
            return nil
        }
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables.first?.columnCount, 2)
        XCTAssertGreaterThanOrEqual(tables.first?.rows.count ?? 0, 2)
        XCTAssertEqual(tables.first?.rows.first?.cells.first?.text, "항목")
    }

    func testSampleDocumentHasKoreanTable() {
        let sample = MockEngine.sampleDocument()
        XCTAssertFalse(sample.isEmpty)
        XCTAssertTrue(sample.plainText.contains("한국어"))
        XCTAssertEqual(sample.metadata.sourceType, .hwpx)
    }

    func testFailureMarkerThrows() {
        XCTAssertThrowsError(try engine.open(data: MockEngine.failureMarker, type: .hwp)) { error in
            guard case HangyeolError.engineFailed = error else {
                return XCTFail("expected HangyeolError.engineFailed, got \(error)")
            }
        }
    }

    func testSaveRoundTripPreservesPlainText() throws {
        let original = MockEngine.sampleDocument()
        let data = try engine.save(original, as: .hwpx)
        let restored = try engine.open(data: data, type: .hwpx)
        XCTAssertEqual(restored.blocks.count, original.blocks.count)
        XCTAssertEqual(restored.plainText, original.plainText)
        XCTAssertEqual(restored.metadata.sourceType, .hwpx)
    }
}

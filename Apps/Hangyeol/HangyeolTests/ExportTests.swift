import AppKit
import PDFKit
import XCTest
@testable import Hangyeol

final class ExportTests: XCTestCase {
    /// Former stub body that must never appear in PDF/print output.
    private let unsupportedPrintLie = "인쇄는 아직 지원하지 않습니다."

    private func paragraphAndTableModel() -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(title: "시험 문서", sourceType: .hwpx),
            blocks: [
                .paragraph(ParagraphBlock(text: "첫 문단")),
                .table(TableBlock(headers: ["가", "나"], body: [["1", "2"]]))
            ]
        )
    }

    private func temporaryPDFURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("hangyeol-export-\(UUID().uuidString).pdf")
    }

    func testExportWritesPDFWithParagraphAndTablePlainText() throws {
        let model = paragraphAndTableModel()
        XCTAssertTrue(model.plainText.contains("첫 문단"))
        XCTAssertTrue(model.plainText.contains("가\t나"))
        XCTAssertTrue(model.plainText.contains("1\t2"))

        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try PDFExporter.export(model, to: url)

        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.starts(with: Data("%PDF".utf8)))
        XCTAssertGreaterThan(data.count, 100)

        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(pdf.pageCount, 1)
        let text = pdf.string ?? ""
        XCTAssertTrue(text.contains("시험 문서"), "PDF should include the title, got: \(text)")
        XCTAssertTrue(text.contains("첫 문단"), "PDF should include paragraph plainText, got: \(text)")
        XCTAssertTrue(text.contains("가"), "PDF should include table header, got: \(text)")
        XCTAssertTrue(text.contains("나"), "PDF should include table header, got: \(text)")
        XCTAssertTrue(text.contains("1"), "PDF should include table cell, got: \(text)")
        XCTAssertTrue(text.contains("2"), "PDF should include table cell, got: \(text)")
        XCTAssertFalse(text.contains(unsupportedPrintLie))
    }

    func testExportEmptyModelWritesPDFWithoutInventingStubBody() throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try PDFExporter.export(.empty, to: url)

        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.starts(with: Data("%PDF".utf8)))
        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(pdf.pageCount, 1)
        let text = pdf.string ?? ""
        XCTAssertTrue(text.contains(L10n.untitled), "empty document still has a title, got: \(text)")
        XCTAssertFalse(text.contains(unsupportedPrintLie))
    }

    func testExportPaginatesLongPlainText() throws {
        let long = String(repeating: "긴 본문 줄입니다. ", count: 400)
        let model = DocumentModel(
            metadata: DocumentMetadata(title: "긴글", sourceType: .hwpx),
            blocks: [.paragraph(ParagraphBlock(text: long))]
        )
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try PDFExporter.export(model, to: url)

        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(pdf.pageCount, 1)
        XCTAssertTrue((pdf.string ?? "").contains("긴 본문 줄입니다"))
    }

    func testPrintFlowHandsPlainTextWithoutStub() {
        let model = paragraphAndTableModel()
        XCTAssertEqual(
            PrintFlow.prepare(isEmpty: false, plainText: model.plainText),
            .ready(model.plainText)
        )
        XCTAssertEqual(PrintFlow.prepare(isEmpty: true, plainText: model.plainText), .skippedEmpty)
        XCTAssertEqual(PrintFlow.prepare(isEmpty: true, plainText: ""), .skippedEmpty)
        if case .ready(let text) = PrintFlow.prepare(isEmpty: false, plainText: model.plainText) {
            XCTAssertTrue(text.contains("첫 문단"))
            XCTAssertTrue(text.contains("가\t나"))
            XCTAssertFalse(text.contains(unsupportedPrintLie))
        } else {
            XCTFail("expected ready plainText")
        }
    }

    @MainActor
    func testPrintViewUsesProvidedTextAndNeverEmbedsStub() {
        let info = NSPrintInfo.shared
        let emptyView = PrintCoordinator.makePrintView(text: "", printInfo: info)
        XCTAssertEqual(emptyView.string, "")
        XCTAssertFalse(emptyView.string.contains(unsupportedPrintLie))

        let model = paragraphAndTableModel()
        let view = PrintCoordinator.makePrintView(text: model.plainText, printInfo: info)
        XCTAssertEqual(view.string, model.plainText)
        XCTAssertFalse(view.string.contains(unsupportedPrintLie))
    }
}

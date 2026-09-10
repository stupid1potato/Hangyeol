import XCTest
@testable import Hangyeol

final class ExportPrintUXTests: XCTestCase {
    func testEmptyDocumentDisablesExportAndPrintWithNextAction() {
        let empty = ExportPresentation.make(isEmpty: true)
        XCTAssertFalse(empty.canExport)
        XCTAssertFalse(empty.canPrint)
        XCTAssertEqual(empty.exportHelp, L10n.exportEmptyHint)
        XCTAssertEqual(empty.printHelp, L10n.printEmptyHint)
        XCTAssertTrue(empty.exportHelp.contains("파일을 열거나"))
        XCTAssertTrue(empty.printHelp.contains("샘플 문서"))
        XCTAssertEqual(empty.exportRetryTitle, L10n.openDocument)
        XCTAssertEqual(L10n.openDocument, "문서 열기…")
        XCTAssertEqual(L10n.exportPDFConfirm, "PDF로 보내기")
        XCTAssertEqual(L10n.printDocument, "인쇄…")
        XCTAssertEqual(L10n.exportPDF, "PDF로 보내기…")
    }

    func testOpenDocumentEnablesExportAndPrint() {
        let ready = ExportPresentation.make(isEmpty: false)
        XCTAssertTrue(ready.canExport)
        XCTAssertTrue(ready.canPrint)
        XCTAssertEqual(ready.exportHelp, L10n.exportPDF)
        XCTAssertEqual(ready.printHelp, L10n.printDocument)
        XCTAssertEqual(ready.exportRetryTitle, L10n.retry)
    }

    func testExportFlowSkipsEmptyWithoutCallingPerform() {
        var called = false
        XCTAssertEqual(
            ExportFlow.export(isEmpty: true) { called = true },
            .skippedEmpty
        )
        XCTAssertFalse(called)
    }

    func testExportFlowMapsExporterFailure() {
        let outcome = ExportFlow.export(isEmpty: false) {
            throw HangyeolError.exportFailed("폴더 권한이 없습니다.")
        }
        XCTAssertEqual(outcome, .failed(.exportFailed("폴더 권한이 없습니다.")))
    }

    func testExportFlowSuccess() {
        var called = false
        XCTAssertEqual(
            ExportFlow.export(isEmpty: false) { called = true },
            .exported
        )
        XCTAssertTrue(called)
    }

    func testPrintFlowEmptyDoesNotInventStubBody() {
        XCTAssertEqual(
            PrintFlow.prepare(isEmpty: true, plainText: "본문"),
            .skippedEmpty
        )
        XCTAssertEqual(
            PrintFlow.prepare(isEmpty: false, plainText: "한결 본문"),
            .ready("한결 본문")
        )
    }

    func testProgressShowsFilenameAndOneStatusLine() {
        let presentation = ExportProgressPresentation.make(filename: "허브-A.pdf")
        XCTAssertEqual(presentation.filename, "허브-A.pdf")
        XCTAssertEqual(presentation.status, L10n.exportProgressStatus)
        XCTAssertEqual(presentation.status, "본문을 PDF로 보내는 중")
        XCTAssertFalse(presentation.status.contains("\n"))
        XCTAssertTrue(presentation.accessibilityLabel.contains("허브-A.pdf"))
        XCTAssertTrue(presentation.accessibilityLabel.contains("본문을 PDF로 보내는 중"))
    }

    func testFailureCopyIncludesCauseAndNextAction() {
        let write = HangyeolError.exportFailed("PDF 파일을 만들 수 없습니다.")
        XCTAssertTrue(write.localizedDescription.contains("PDF로 보내지 못했습니다"))
        XCTAssertTrue(write.localizedDescription.contains("PDF 파일을 만들 수 없습니다"))
        XCTAssertTrue((write.recoverySuggestion ?? "").contains("다시 보내"))

        let emptyExport = HangyeolError.exportEmptyDocument
        XCTAssertEqual(emptyExport.localizedDescription, "이 창에는 보낼 본문이 없습니다.")
        XCTAssertTrue((emptyExport.recoverySuggestion ?? "").contains("파일을 열거나"))
        XCTAssertEqual(ExportPresentation.retryTitle(for: emptyExport), "문서 열기…")
        XCTAssertTrue(ExportPresentation.retryHint(for: emptyExport).contains("다시 보내"))

        let emptyPrint = HangyeolError.printEmptyDocument
        XCTAssertEqual(emptyPrint.localizedDescription, "이 창에는 인쇄할 본문이 없습니다.")
        XCTAssertTrue((emptyPrint.recoverySuggestion ?? "").contains("샘플 문서"))

        let label = FailureSheetA11y.label(title: L10n.exportFailureTitle, error: write)
        XCTAssertTrue(label.contains(L10n.exportFailureTitle))
        XCTAssertTrue(label.contains("다시 보내"))
    }

    func testUserFacingCopyDropsStubLanguage() {
        XCTAssertEqual(L10n.exportPDFMessage, "본문을 PDF 파일로 보냅니다.")
        XCTAssertFalse(L10n.exportPDFMessage.contains("아직"))
        XCTAssertFalse(L10n.exportPDFMessage.localizedCaseInsensitiveContains("stub"))
        XCTAssertFalse(L10n.exportPDFMessage.contains("스텁"))
        XCTAssertFalse(L10n.exportProgressStatus.contains("1주차"))
        XCTAssertFalse(L10n.printEmptyHint.contains("아직 지원하지 않습니다"))
        XCTAssertFalse(L10n.exportEmptyHint.localizedCaseInsensitiveContains("Mock"))
        XCTAssertFalse(L10n.exportEmptyHint.localizedCaseInsensitiveContains("XCFramework"))
        XCTAssertEqual(L10n.exportFailureRetryHint, "같은 위치에 다시 보냅니다.")
    }

    func testDocumentWindowWiresExportPrintAndProgress() throws {
        let window = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views/DocumentWindow.swift")
        let source = try String(contentsOf: window, encoding: .utf8)
        XCTAssertTrue(source.contains("ExportFlow.export"))
        XCTAssertTrue(source.contains("PrintFlow.prepare"))
        XCTAssertTrue(source.contains("exportProgress"))
        XCTAssertTrue(source.contains("ExportProgressSheet"))
        XCTAssertTrue(source.contains("exportEmptyDocument"))
        XCTAssertTrue(source.contains("printEmptyDocument"))
        XCTAssertTrue(source.contains("L10n.exportPDFConfirm"))
        XCTAssertFalse(source.contains("printStub"))
        XCTAssertFalse(source.contains("인쇄는 아직 지원하지 않습니다"))
    }

    func testPrintCoordinatorAndExporterDropStubCopy() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol")
        let printSource = try String(
            contentsOf: root.appendingPathComponent("Export/PrintCoordinator.swift"),
            encoding: .utf8
        )
        XCTAssertFalse(printSource.contains("printStub"))
        XCTAssertFalse(printSource.contains("1주차 스텁"))
        XCTAssertFalse(printSource.contains("아직 지원하지 않습니다"))
        XCTAssertTrue(printSource.contains("PrintFlow.prepare"))

        let pdfSource = try String(
            contentsOf: root.appendingPathComponent("Export/PDFExporter.swift"),
            encoding: .utf8
        )
        XCTAssertFalse(pdfSource.contains("1주차 스텁"))
        XCTAssertTrue(pdfSource.contains("exportFailed"))

        let strings = try String(
            contentsOf: root.appendingPathComponent("Resources/ko.lproj/Localizable.strings"),
            encoding: .utf8
        )
        XCTAssertFalse(strings.contains("print.stub"))
        XCTAssertFalse(strings.contains("인쇄는 아직 지원하지 않습니다"))
    }
}

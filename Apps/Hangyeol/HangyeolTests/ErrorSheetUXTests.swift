import XCTest
@testable import Hangyeol

final class ErrorSheetUXTests: XCTestCase {
    func testLiveOpenAndSaveKindsHaveDistinctTitleCauseAndNextAction() {
        let encrypted = ErrorSheetPresentation.make(error: .encrypted)
        XCTAssertEqual(encrypted.title, "암호 문서는 열 수 없습니다")
        XCTAssertEqual(encrypted.cause, L10n.errorEncryptedCause)
        XCTAssertEqual(encrypted.nextAction, L10n.errorEncryptedRecovery)
        XCTAssertNotEqual(encrypted.title, encrypted.cause)
        XCTAssertTrue((encrypted.nextAction ?? "").contains("다른 파일"))
        XCTAssertFalse(encrypted.accessibilityLabel.contains("ENCRYPTED"))
        XCTAssertEqual(encrypted.kindIdentifier, "error-kind-encrypted")

        let corrupt = ErrorSheetPresentation.make(error: .corrupt)
        XCTAssertEqual(corrupt.title, "손상된 파일은 열 수 없습니다")
        XCTAssertEqual(corrupt.cause, L10n.errorCorruptCause)
        XCTAssertEqual(corrupt.nextAction, L10n.errorCorruptRecovery)
        XCTAssertNotEqual(corrupt.title, corrupt.cause)
        XCTAssertFalse(corrupt.accessibilityLabel.contains("CORRUPT"))
        XCTAssertEqual(corrupt.kindIdentifier, "error-kind-corrupt")

        let unsupported = ErrorSheetPresentation.make(error: .unsupported)
        XCTAssertEqual(unsupported.title, "이 문서 형식은 열 수 없습니다")
        XCTAssertEqual(unsupported.cause, L10n.errorUnsupportedCause)
        XCTAssertEqual(unsupported.nextAction, L10n.errorUnsupportedRecovery)
        XCTAssertNotEqual(unsupported.title, unsupported.cause)
        XCTAssertFalse(unsupported.accessibilityLabel.contains("UNSUPPORTED"))
        XCTAssertEqual(unsupported.kindIdentifier, "error-kind-unsupported")

        let unsupportedType = ErrorSheetPresentation.make(error: .unsupportedType("notes.txt"))
        XCTAssertEqual(unsupportedType.title, "선택한 파일은 열 수 없습니다")
        XCTAssertNotEqual(unsupportedType.title, unsupported.title)
        XCTAssertTrue(unsupportedType.cause.contains("notes.txt"))
        XCTAssertEqual(unsupportedType.nextAction, L10n.errorUnsupportedTypeRecovery)
        XCTAssertEqual(unsupportedType.kindIdentifier, "error-kind-unsupported-type")

        let saveRejected = ErrorSheetPresentation.make(error: .saveRejected, context: .save)
        XCTAssertEqual(saveRejected.title, "HWP로는 저장할 수 없습니다")
        XCTAssertNotEqual(saveRejected.title, L10n.saveFailureTitle)
        XCTAssertEqual(saveRejected.cause, L10n.errorSaveRejectedCause)
        XCTAssertTrue((saveRejected.nextAction ?? "").contains("HWPX"))
        XCTAssertFalse(saveRejected.cause.contains("SAVE_REJECTED"))
        XCTAssertEqual(saveRejected.kindIdentifier, "error-kind-save-rejected")
        XCTAssertEqual(saveRejected.sheetIdentifier, "save-failure-sheet")
    }

    func testEmptyFileAndEngineFailedKeepDistinctOpenTitles() {
        let empty = ErrorSheetPresentation.make(error: .emptyFile)
        XCTAssertEqual(empty.title, L10n.errorEmptyFileTitle)
        XCTAssertTrue(empty.cause.contains("비어") || empty.cause.contains("열 수 없습니다"))
        XCTAssertTrue((empty.nextAction ?? "").contains("HWP"))
        XCTAssertTrue(empty.accessibilityLabel.contains(L10n.errorNextAction))

        let engine = ErrorSheetPresentation.make(error: .engineFailed("연결 실패"))
        XCTAssertEqual(engine.title, L10n.errorEngineFailedTitle)
        XCTAssertTrue(engine.cause.contains("연결 실패"))
        XCTAssertEqual(engine.kindIdentifier, "error-kind-engine-failed")
    }

    func testExportAndPrintContextKeepSheetTitlesAndIdentifiers() {
        let export = ErrorSheetPresentation.make(
            error: .exportFailed("폴더 권한이 없습니다."),
            context: .export
        )
        XCTAssertEqual(export.title, L10n.exportFailureTitle)
        XCTAssertEqual(export.sheetIdentifier, "export-failure-sheet")
        XCTAssertTrue((export.nextAction ?? "").contains("다시 보내"))

        let emptyExport = ErrorSheetPresentation.make(
            error: .exportEmptyDocument,
            context: .export
        )
        XCTAssertEqual(emptyExport.title, L10n.exportFailureTitle)
        XCTAssertTrue(emptyExport.cause.contains("보낼 본문"))

        let printEmpty = ErrorSheetPresentation.make(
            error: .printEmptyDocument,
            context: .print
        )
        XCTAssertEqual(printEmpty.title, L10n.printFailureTitle)
        XCTAssertEqual(printEmpty.sheetIdentifier, "print-failure-sheet")
    }

    func testContextTitlesWhenKindHasNoDistinctTitle() {
        let save = ErrorSheetPresentation.make(
            error: .saveFailed("디스크가 가득 찼습니다."),
            context: .save
        )
        XCTAssertEqual(save.title, L10n.saveFailureTitle)

        let paragraph = ErrorSheetPresentation.make(
            error: .engineFailed("세션 없음"),
            context: .paragraph
        )
        XCTAssertEqual(paragraph.title, L10n.paragraphEditFailureTitle)

        let table = ErrorSheetPresentation.make(
            error: .saveFailed("칸 저장 실패"),
            context: .tableCell
        )
        XCTAssertEqual(table.title, L10n.tableCellEditFailureTitle)
    }

    func testFailureSheetA11yUsesCauseAndNextActionHeading() {
        let error = HangyeolError.saveFailed("디스크가 가득 찼습니다.")
        let label = FailureSheetA11y.label(title: L10n.saveFailureTitle, error: error)
        XCTAssertTrue(label.contains(L10n.saveFailureTitle))
        XCTAssertTrue(label.contains("디스크가 가득 찼습니다"))
        XCTAssertTrue(label.contains(L10n.errorNextAction))
        XCTAssertTrue(label.contains(error.recoverySuggestion ?? ""))
    }

    func testDocumentWindowWiresOpenErrorSheetToPresentation() throws {
        let window = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Views/DocumentWindow.swift")
        let source = try String(contentsOf: window, encoding: .utf8)
        XCTAssertTrue(source.contains("openErrorSheetBinding"))
        XCTAssertTrue(source.contains("context: .generic"))
        XCTAssertTrue(source.contains("HelpSheet"))
        XCTAssertFalse(source.contains(".alert(L10n.help"))
    }
}

final class HelpUXTests: XCTestCase {
    func testKnownLimitsAreScannableKoreanFacts() {
        let help = HelpPresentation.make()
        XCTAssertEqual(help.title, L10n.help)
        XCTAssertEqual(help.limitsTitle, "알려진 한계")
        XCTAssertEqual(help.limits.count, 9)
        XCTAssertEqual(
            help.limits.map(\.id),
            [
                "layout",
                "hwp-save",
                "encrypted",
                "open-errors",
                "unsupported-formats",
                "edit-subset",
                "images",
                "pdf-print",
                "mvp-out"
            ]
        )

        XCTAssertTrue(help.body.contains("열기"))
        XCTAssertTrue(help.body.contains("PDF"))
        XCTAssertFalse(help.body.contains("HANGYEOL_USE_MOCK"))

        let joined = help.limits.map(\.text).joined(separator: " ")
        XCTAssertTrue(joined.contains("조판"))
        XCTAssertTrue(joined.contains("한/글"))
        XCTAssertTrue(joined.contains("WYSIWYG"))
        XCTAssertTrue(joined.contains("구조화"))
        XCTAssertTrue(joined.contains(".hwp"))
        XCTAssertTrue(joined.contains("HWPX"))
        XCTAssertTrue(joined.contains("암호"))
        XCTAssertTrue(joined.contains("풀지"))
        XCTAssertTrue(joined.contains("손상"))
        XCTAssertTrue(joined.contains("빈 파일"))
        XCTAssertTrue(joined.contains("오류 안내"))
        XCTAssertTrue(joined.contains("DRM"))
        XCTAssertTrue(joined.contains("HWP 3.x"))
        XCTAssertTrue(joined.contains("HML"))
        XCTAssertTrue(joined.contains("표 칸"))
        XCTAssertTrue(joined.contains("문단"))
        XCTAssertTrue(joined.contains("행"))
        XCTAssertTrue(joined.contains("머리글"))
        XCTAssertTrue(joined.contains("그림"))
        XCTAssertTrue(joined.contains("남을 수 있습니다"))
        XCTAssertTrue(joined.contains("인쇄"))
        XCTAssertTrue(joined.contains("자동 업데이트"))
        XCTAssertTrue(joined.contains("미리보기"))
        XCTAssertFalse(joined.contains("SAVE_REJECTED"))
        XCTAssertFalse(joined.contains("HangyeolError"))
        XCTAssertFalse(joined.contains("Sparkle"))
        XCTAssertFalse(joined.localizedCaseInsensitiveContains("Quick Look"))
        XCTAssertFalse(joined.contains("HANGYEOL_USE_MOCK"))
        XCTAssertFalse(joined.contains("KitRealEngine"))
        XCTAssertFalse(joined.contains("HG_"))
        XCTAssertFalse(joined.localizedCaseInsensitiveContains("freeze"))
        XCTAssertFalse(joined.contains("BinData"))
        XCTAssertFalse(joined.contains("XCFramework"))
        XCTAssertFalse(joined.contains("FFI"))
        XCTAssertFalse(joined.contains("Mock"))
        XCTAssertFalse(joined.contains("keep-on-save"))
        XCTAssertEqual(HelpPresentation.sheetIdentifier, "help-sheet")
        XCTAssertEqual(HelpPresentation.limitsIdentifier, "help-known-limits")
    }

    func testHelpSheetKeepsPrimaryCopyAndLimitIdentifiers() throws {
        let sheet = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/Sheets/HelpSheet.swift")
        let source = try String(contentsOf: sheet, encoding: .utf8)
        XCTAssertTrue(source.contains(".foregroundStyle(.primary)"))
        XCTAssertFalse(source.contains(".foregroundStyle(.secondary)"))
        XCTAssertTrue(source.contains("help-limit-\\(item.id)"))
        XCTAssertTrue(source.contains("HelpPresentation.limitsIdentifier"))
        XCTAssertTrue(source.contains("HelpPresentation.sheetIdentifier"))
    }

    func testHelpMenuExposesKnownLimits() throws {
        let commands = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Hangyeol/App/HangyeolCommands.swift")
        let source = try String(contentsOf: commands, encoding: .utf8)
        XCTAssertTrue(source.contains("L10n.helpKnownLimitsTitle"))
        XCTAssertTrue(source.contains("showHelp"))
    }

    func testEmptyStateIdentifiersAndCopy() {
        XCTAssertEqual(EmptyStatePresentation.rootIdentifier, "empty-state")
        XCTAssertEqual(EmptyStatePresentation.openSampleIdentifier, "empty-state-open-sample")
        XCTAssertEqual(EmptyStatePresentation.openDocumentIdentifier, "empty-state-open-document")
        XCTAssertTrue(L10n.week1Note.contains("HWP"))
        XCTAssertNotEqual(L10n.openSampleHint, L10n.openSample)
        XCTAssertNotEqual(L10n.openDocumentHint, L10n.openDocument)
    }
}

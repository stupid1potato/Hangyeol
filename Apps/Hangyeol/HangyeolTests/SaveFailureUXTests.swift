import XCTest
@testable import Hangyeol

final class SaveFailureUXTests: XCTestCase {
    func testHangyeolDocumentEquatableTracksModelEdits() {
        var document = HangyeolDocument()
        let pristine = document
        XCTAssertEqual(document, pristine)

        document.model.metadata.title = "메모"
        XCTAssertNotEqual(document, pristine)
        XCTAssertEqual(document.model.displayTitle, "메모")
    }

    func testChromeShowsEditedSubtitleAndVoiceOverLabel() {
        let clean = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: nil,
            windowEdited: false
        )
        XCTAssertEqual(clean.title, "보고서")
        XCTAssertFalse(clean.isEdited)
        XCTAssertNil(clean.navigationSubtitle)
        XCTAssertEqual(clean.accessibilityLabel, "보고서")

        let dirtyFromWindow = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: nil,
            windowEdited: true
        )
        XCTAssertEqual(dirtyFromWindow.navigationSubtitle, L10n.edited)
        XCTAssertTrue(dirtyFromWindow.accessibilityLabel.contains(L10n.edited))

        let overrideWins = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: false,
            windowEdited: true
        )
        XCTAssertFalse(overrideWins.isEdited)
        XCTAssertNil(overrideWins.navigationSubtitle)

        let publishedDirty = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: true,
            windowEdited: false
        )
        XCTAssertTrue(publishedDirty.isEdited)
        XCTAssertEqual(publishedDirty.navigationSubtitle, L10n.edited)
    }

    func testFailureSheetA11yJoinsCauseAndRecovery() {
        let error = HangyeolError.saveFailed("디스크가 가득 찼습니다.")
        let label = FailureSheetA11y.label(title: L10n.saveFailureTitle, error: error)
        XCTAssertTrue(label.contains(L10n.saveFailureTitle))
        XCTAssertTrue(label.contains("디스크가 가득 찼습니다."))
        XCTAssertEqual(error.recoverySuggestion, L10nErrorCopy.saveFailedRecovery)
        XCTAssertTrue(label.contains(error.recoverySuggestion ?? ""))
    }

    func testSaveAndReopenErrorCopyIncludesCauseAndNextAction() {
        let save = HangyeolError.saveFailed("권한 없음")
        XCTAssertTrue(save.localizedDescription.contains("권한 없음"))
        XCTAssertTrue((save.recoverySuggestion ?? "").contains("다시 저장"))

        let bookmark = HangyeolError.bookmarkFailed("북마크가 만료됨")
        XCTAssertTrue(bookmark.localizedDescription.contains("북마크가 만료됨"))
        XCTAssertTrue((bookmark.recoverySuggestion ?? "").contains("다시 열"))

        let empty = HangyeolError.emptyFile
        XCTAssertTrue(empty.localizedDescription.contains("열 수 없습니다"))
        XCTAssertTrue((empty.recoverySuggestion ?? "").contains("HWP"))
    }

    @MainActor
    func testRetryableFailureRetryInvokesHandlerOnce() {
        let failure = RetryableFailure()
        var retries = 0
        failure.present(.saveFailed("임시")) { retries += 1 }

        XCTAssertEqual(failure.error, .saveFailed("임시"))
        XCTAssertTrue(failure.hasRetry)

        failure.retry()
        XCTAssertNil(failure.error)
        XCTAssertFalse(failure.hasRetry)
        XCTAssertEqual(retries, 1)

        failure.retry()
        XCTAssertEqual(retries, 1)
    }

    @MainActor
    func testSheetBindingNilClearsRetryHandler() {
        let failure = RetryableFailure()
        var retries = 0
        failure.present(.saveFailed("임시")) { retries += 1 }
        failure.sheetBinding.wrappedValue = nil
        XCTAssertNil(failure.error)
        XCTAssertFalse(failure.hasRetry)
        XCTAssertEqual(retries, 0)
    }

    @MainActor
    func testRetryableFailureCancelDoesNotRetry() {
        let failure = RetryableFailure()
        var retries = 0
        failure.present(.bookmarkFailed("권한 없음")) { retries += 1 }
        failure.dismiss()
        XCTAssertNil(failure.error)
        XCTAssertEqual(retries, 0)
    }

    func testUserFacingCopyAvoidsEngineJargon() {
        XCTAssertFalse(L10n.week1Note.localizedCaseInsensitiveContains("XCFramework"))
        XCTAssertFalse(L10n.week1Note.localizedCaseInsensitiveContains("Mock"))
        XCTAssertFalse(L10n.helpBody.contains("HANGYEOL_USE_MOCK"))
        XCTAssertEqual(L10n.retrySave, "다시 저장")
        XCTAssertEqual(L10n.retryOpen, "다시 열기")
        XCTAssertEqual(L10n.edited, "편집됨")
    }
}

private enum L10nErrorCopy {
    static let saveFailedRecovery = String(
        localized: "error.saveFailed.recovery",
        defaultValue: "저장 위치를 바꾸거나 폴더 권한을 확인한 뒤 다시 저장하세요."
    )
}

import XCTest
@testable import Hangyeol

final class SaveFailureUXTests: XCTestCase {
    func testChromeBindsHasUnsavedEdits() {
        var document = HangyeolDocument()
        XCTAssertFalse(document.hasUnsavedEdits)

        let clean = DocumentChromeState.make(
            title: document.model.displayTitle,
            isEditedOverride: nil,
            hasUnsavedEdits: document.hasUnsavedEdits
        )
        XCTAssertFalse(clean.isEdited)
        XCTAssertNil(clean.navigationSubtitle)

        document.hasUnsavedEdits = true
        let dirty = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: nil,
            hasUnsavedEdits: document.hasUnsavedEdits
        )
        XCTAssertEqual(dirty.navigationSubtitle, L10n.edited)
        XCTAssertTrue(dirty.accessibilityLabel.contains(L10n.edited))

        let overrideWins = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: false,
            hasUnsavedEdits: true
        )
        XCTAssertFalse(overrideWins.isEdited)

        let previewDirty = DocumentChromeState.make(
            title: "보고서",
            isEditedOverride: true,
            hasUnsavedEdits: false
        )
        XCTAssertTrue(previewDirty.isEdited)
    }

    func testSessionSaveFailurePresentsLastSaveErrorUntilDismissed() {
        let error = HangyeolError.saveFailed("디스크가 가득 찼습니다.")
        XCTAssertEqual(
            SessionSaveFailurePresentation.presentedError(lastSaveError: error, dismissedID: nil),
            error
        )
        XCTAssertNil(
            SessionSaveFailurePresentation.presentedError(lastSaveError: error, dismissedID: error.id)
        )
        XCTAssertNil(
            SessionSaveFailurePresentation.presentedError(lastSaveError: nil, dismissedID: nil)
        )

        let next = HangyeolError.saveRejected
        XCTAssertEqual(
            SessionSaveFailurePresentation.presentedError(lastSaveError: next, dismissedID: error.id),
            next
        )
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
        XCTAssertTrue(empty.localizedDescription.contains("비어"))
        XCTAssertTrue((empty.recoverySuggestion ?? "").contains("HWP"))
        XCTAssertEqual(ErrorSheetPresentation.make(error: empty).title, "빈 파일은 열 수 없습니다")

        XCTAssertFalse(HangyeolError.saveRejected.localizedDescription.contains("SAVE_REJECTED"))
        XCTAssertTrue((HangyeolError.saveRejected.recoverySuggestion ?? "").contains("HWPX"))

        XCTAssertFalse(HangyeolError.encrypted.localizedDescription.contains("ENCRYPTED"))
        XCTAssertFalse(HangyeolError.corrupt.localizedDescription.contains("CORRUPT"))
        XCTAssertFalse(HangyeolError.unsupported.localizedDescription.contains("UNSUPPORTED"))
    }

    func testSessionOpenFailurePresentationMirrorsDismissedID() {
        let error = HangyeolError.corrupt
        XCTAssertEqual(
            SessionOpenFailurePresentation.presentedError(lastOpenError: error, dismissedID: nil),
            error
        )
        XCTAssertNil(
            SessionOpenFailurePresentation.presentedError(lastOpenError: error, dismissedID: error.id)
        )
        XCTAssertEqual(
            SessionOpenFailurePresentation.presentedError(
                lastOpenError: .encrypted,
                dismissedID: error.id
            ),
            .encrypted
        )
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

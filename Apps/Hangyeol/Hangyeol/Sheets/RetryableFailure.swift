import Foundation
import SwiftUI

/// UI-only presentation state for Retry/Cancel sheets (PDF export).
/// Document save failures bind to `DocumentSession.lastSaveError` instead.
@MainActor
final class RetryableFailure: ObservableObject {
    @Published private(set) var error: HangyeolError?
    private var retryHandler: (() -> Void)?

    var hasRetry: Bool { retryHandler != nil }

    var sheetBinding: Binding<HangyeolError?> {
        Binding(
            get: { self.error },
            set: { newValue in
                if newValue == nil {
                    self.dismiss()
                } else {
                    self.error = newValue
                }
            }
        )
    }

    func present(_ error: HangyeolError, retry: @escaping () -> Void) {
        retryHandler = retry
        self.error = error
    }

    func retry() {
        let handler = retryHandler
        dismiss()
        handler?()
    }

    func dismiss() {
        error = nil
        retryHandler = nil
    }
}

/// Presents `DocumentSession.lastSaveError` without a parallel error store.
enum SessionSaveFailurePresentation {
    static func presentedError(lastSaveError: HangyeolError?, dismissedID: String?) -> HangyeolError? {
        SessionOpenFailurePresentation.presentedError(
            lastOpenError: lastSaveError,
            dismissedID: dismissedID
        )
    }
}

/// Presents `DocumentSession.lastOpenError` on ErrorSheet (`presentedError`).
enum SessionOpenFailurePresentation {
    static func presentedError(lastOpenError: HangyeolError?, dismissedID: String?) -> HangyeolError? {
        guard let error = lastOpenError else { return nil }
        if dismissedID == error.id { return nil }
        return error
    }
}

/// VoiceOver string for failure sheets: title + cause + next action.
enum FailureSheetA11y {
    static func label(title: String, cause: String, nextAction: String?) -> String {
        var parts = [title, cause]
        if let nextAction, !nextAction.isEmpty {
            parts.append(L10n.errorNextAction)
            parts.append(nextAction)
        }
        return parts.joined(separator: " ")
    }

    static func label(title: String, error: HangyeolError) -> String {
        let presentation = ErrorSheetPresentation.make(error: error, titleOverride: title)
        return presentation.accessibilityLabel
    }
}

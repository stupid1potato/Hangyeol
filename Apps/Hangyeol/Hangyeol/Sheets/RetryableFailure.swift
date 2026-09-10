import Foundation
import SwiftUI

/// UI-only presentation state for Retry/Cancel sheets.
/// Does not own an engine session; the caller supplies the retry closure
/// (PDF export today; document save when HangyeolDocument publishes a failure).
@MainActor
final class RetryableFailure: ObservableObject {
    @Published private(set) var error: HangyeolError?
    private var retryHandler: (() -> Void)?

    var hasRetry: Bool { retryHandler != nil }

    var sheetBinding: Binding<HangyeolError?> {
        Binding(
            get: { error },
            set: { newValue in
                if newValue == nil {
                    dismiss()
                } else {
                    error = newValue
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

/// VoiceOver string for failure sheets: title + cause + next action.
enum FailureSheetA11y {
    static func label(title: String, error: HangyeolError) -> String {
        var parts = [title, error.localizedDescription]
        if let suggestion = error.recoverySuggestion, !suggestion.isEmpty {
            parts.append(suggestion)
        }
        return parts.joined(separator: " ")
    }
}

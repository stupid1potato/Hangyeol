import Foundation

/// Find/Replace bar state derived from **this** document's session (`canReplace`).
/// Testable without AppKit; Views must not call the process-wide engine probe.
struct FindReplacePresentation: Equatable {
    var canReplace: Bool
    var query: String
    var lastReplacementCount: Int?
    /// Bumped after a successful replace so VoiceOver focus can move to the count.
    var statusFocusToken: Int

    var isReplaceEnabled: Bool {
        canReplace && !query.isEmpty
    }

    /// Session API is replace-all (`replaceText` → `Int`). Find-next is not wired.
    var isFindNextEnabled: Bool { false }

    var shouldFocusStatus: Bool {
        lastReplacementCount != nil && statusFocusToken > 0
    }

    var statusCaption: String {
        if !canReplace {
            return L10n.findStubNote
        }
        if let count = lastReplacementCount {
            return L10n.replacedCount(count)
        }
        return L10n.findLiveNote
    }

    static func make(
        canReplace: Bool,
        query: String,
        lastReplacementCount: Int?,
        statusFocusToken: Int = 0
    ) -> FindReplacePresentation {
        FindReplacePresentation(
            canReplace: canReplace,
            query: query,
            lastReplacementCount: lastReplacementCount,
            statusFocusToken: statusFocusToken
        )
    }
}

/// View-layer replace gate: no fake success when the session cannot replace.
enum FindReplaceFlow {
    enum Outcome: Equatable {
        case skippedUnavailable
        case skippedEmptyQuery
        case replaced(Int)
        case failed(HangyeolError)
    }

    static func replace(
        canReplace: Bool,
        find: String,
        replace: String,
        perform: (String, String) throws -> Int
    ) -> Outcome {
        guard canReplace else { return .skippedUnavailable }
        guard !find.isEmpty else { return .skippedEmptyQuery }
        do {
            return .replaced(try perform(find, replace))
        } catch let error as HangyeolError {
            return .failed(error)
        } catch {
            return .failed(.engineFailed(error.localizedDescription))
        }
    }
}

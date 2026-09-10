import Foundation

/// Empty-window a11y identifiers and VoiceOver hints. Copy lives in `L10n`.
enum EmptyStatePresentation {
    static let rootIdentifier = "empty-state"
    static let openSampleIdentifier = "empty-state-open-sample"
    static let openDocumentIdentifier = "empty-state-open-document"
    static let recentsIdentifier = "empty-state-recents"
    static let recentsEmptyIdentifier = "empty-state-recents-empty"

    static func recentIdentifier(title: String) -> String {
        "empty-state-recent-\(title)"
    }
}

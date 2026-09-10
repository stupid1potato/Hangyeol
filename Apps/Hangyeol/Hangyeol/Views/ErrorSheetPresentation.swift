import Foundation

/// Views-side error sheet: distinct title + cause + next action.
/// Wires live `HangyeolError.encrypted` / `.corrupt` / `.unsupported` /
/// `.unsupportedType` / `.saveRejected`. Copy lives in L10n; Document mapping
/// is owned by 개발자2.
struct ErrorSheetPresentation: Equatable {
    enum Context: Equatable {
        case generic
        case save
        case export
        case print
        case reopen
        case paragraph
        case tableCell

        var defaultTitle: String {
            switch self {
            case .generic: return L10n.errorTitle
            case .save: return L10n.saveFailureTitle
            case .export: return L10n.exportFailureTitle
            case .print: return L10n.printFailureTitle
            case .reopen: return L10n.reopenFailureTitle
            case .paragraph: return L10n.paragraphEditFailureTitle
            case .tableCell: return L10n.tableCellEditFailureTitle
            }
        }

        var sheetIdentifier: String {
            switch self {
            case .save: return "save-failure-sheet"
            case .export: return "export-failure-sheet"
            case .print: return "print-failure-sheet"
            case .generic, .reopen, .paragraph, .tableCell: return "error-sheet"
            }
        }
    }

    var title: String
    var cause: String
    var nextAction: String?
    var kindIdentifier: String
    var sheetIdentifier: String

    var accessibilityLabel: String {
        FailureSheetA11y.label(title: title, cause: cause, nextAction: nextAction)
    }

    static func make(
        error: HangyeolError,
        context: Context = .generic,
        titleOverride: String? = nil
    ) -> ErrorSheetPresentation {
        ErrorSheetPresentation(
            title: title(for: error, context: context, override: titleOverride),
            cause: cause(for: error),
            nextAction: nextAction(for: error),
            kindIdentifier: kindIdentifier(for: error),
            sheetIdentifier: context.sheetIdentifier
        )
    }

    private static func title(
        for error: HangyeolError,
        context: Context,
        override: String?
    ) -> String {
        if let distinct = distinctTitle(for: error, context: context) {
            return distinct
        }
        if let override, !override.isEmpty {
            return override
        }
        return context.defaultTitle
    }

    /// Dedicated open/save kinds always win over a generic sheet title.
    private static func distinctTitle(for error: HangyeolError, context: Context) -> String? {
        switch error {
        case .encrypted:
            return L10n.errorEncryptedTitle
        case .corrupt:
            return L10n.errorCorruptTitle
        case .unsupported:
            return L10n.errorUnsupportedTitle
        case .unsupportedType:
            return L10n.errorUnsupportedTypeTitle
        case .saveRejected:
            return L10n.errorSaveRejectedTitle
        case .emptyFile:
            return L10n.errorEmptyFileTitle
        case .engineFailed:
            if context == .paragraph || context == .tableCell {
                return nil
            }
            if context == .generic || context == .reopen {
                return L10n.errorEngineFailedTitle
            }
            return nil
        default:
            return nil
        }
    }

    private static func cause(for error: HangyeolError) -> String {
        switch error {
        case .encrypted:
            return L10n.errorEncryptedCause
        case .corrupt:
            return L10n.errorCorruptCause
        case .unsupported:
            return L10n.errorUnsupportedCause
        case .saveRejected:
            return L10n.errorSaveRejectedCause
        default:
            return error.localizedDescription
        }
    }

    private static func nextAction(for error: HangyeolError) -> String? {
        switch error {
        case .encrypted:
            return L10n.errorEncryptedRecovery
        case .corrupt:
            return L10n.errorCorruptRecovery
        case .unsupported:
            return L10n.errorUnsupportedRecovery
        case .unsupportedType:
            return L10n.errorUnsupportedTypeRecovery
        case .saveRejected:
            return L10n.errorSaveRejectedRecovery
        default:
            return error.recoverySuggestion
        }
    }

    private static func kindIdentifier(for error: HangyeolError) -> String {
        switch error {
        case .encrypted:
            return "error-kind-encrypted"
        case .corrupt:
            return "error-kind-corrupt"
        case .unsupported:
            return "error-kind-unsupported"
        case .unsupportedType:
            return "error-kind-unsupported-type"
        case .saveRejected:
            return "error-kind-save-rejected"
        case .emptyFile:
            return "error-kind-empty-file"
        case .engineFailed:
            return "error-kind-engine-failed"
        case .exportEmptyDocument:
            return "error-kind-export-empty"
        case .printEmptyDocument:
            return "error-kind-print-empty"
        case .exportFailed:
            return "error-kind-export-failed"
        case .saveFailed:
            return "error-kind-save-failed"
        case .bookmarkFailed:
            return "error-kind-bookmark-failed"
        case .sampleNotFound:
            return "error-kind-sample-not-found"
        case .notYetImplemented:
            return "error-kind-not-implemented"
        }
    }
}

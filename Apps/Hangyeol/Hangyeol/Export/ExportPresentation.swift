import Foundation

/// PDF export / print chrome. Empty untitled windows do not pretend to send or print.
struct ExportPresentation: Equatable {
    var isEmpty: Bool

    var canExport: Bool { !isEmpty }
    var canPrint: Bool { !isEmpty }

    var exportHelp: String {
        canExport ? L10n.exportPDF : L10n.exportEmptyHint
    }

    var printHelp: String {
        canPrint ? L10n.printDocument : L10n.printEmptyHint
    }

    var exportRetryTitle: String {
        isEmpty ? L10n.openDocument : L10n.retry
    }

    var exportRetryHint: String {
        isEmpty ? L10n.exportEmptyRetryHint : L10n.exportFailureRetryHint
    }

    static func make(isEmpty: Bool) -> ExportPresentation {
        ExportPresentation(isEmpty: isEmpty)
    }

    static func retryTitle(for error: HangyeolError) -> String {
        error == .exportEmptyDocument ? L10n.openDocument : L10n.retry
    }

    static func retryHint(for error: HangyeolError) -> String {
        error == .exportEmptyDocument ? L10n.exportEmptyRetryHint : L10n.exportFailureRetryHint
    }
}

/// Filename + one status line for the PDF progress sheet.
struct ExportProgressPresentation: Equatable, Identifiable {
    var filename: String
    var status: String

    var id: String { filename }

    var accessibilityLabel: String {
        L10n.exportProgressA11y(filename: filename, status: status)
    }

    static func make(
        filename: String,
        status: String = L10n.exportProgressStatus
    ) -> ExportProgressPresentation {
        ExportProgressPresentation(filename: filename, status: status)
    }
}

/// View-layer PDF export: empty documents never call the exporter.
enum ExportFlow {
    enum Outcome: Equatable {
        case skippedEmpty
        case exported
        case failed(HangyeolError)
    }

    static func export(isEmpty: Bool, perform: () throws -> Void) -> Outcome {
        guard !isEmpty else { return .skippedEmpty }
        do {
            try perform()
            return .exported
        } catch let error as HangyeolError {
            return .failed(error)
        } catch {
            return .failed(.exportFailed(error.localizedDescription))
        }
    }
}

/// View-layer print: empty documents never open the system print panel.
enum PrintFlow {
    enum Outcome: Equatable {
        case skippedEmpty
        case ready(String)
    }

    static func prepare(isEmpty: Bool, plainText: String) -> Outcome {
        guard !isEmpty else { return .skippedEmpty }
        return .ready(plainText)
    }
}

import SwiftUI

struct ErrorSheet: View {
    let error: HangyeolError
    var context: ErrorSheetPresentation.Context = .generic
    var title: String? = nil
    var retryTitle: String = L10n.retry
    var retryHint: String? = nil
    var onRetry: (() -> Void)? = nil
    var onDismiss: () -> Void

    private var presentation: ErrorSheetPresentation {
        ErrorSheetPresentation.make(error: error, context: context, titleOverride: title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(presentation.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(presentation.kindIdentifier)
            }

            Text(presentation.cause)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("error-sheet-cause")

            if let suggestion = presentation.nextAction {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.errorNextAction)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("error-sheet-next-heading")
                    Text(suggestion)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("error-sheet-next")
                }
            }

            HStack {
                Spacer()
                if onRetry != nil {
                    Button(L10n.cancel, action: onDismiss)
                        .keyboardShortcut(.cancelAction)
                    Button(retryTitle) {
                        onRetry?()
                    }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint(retryHint ?? retryTitle)
                } else {
                    Button(L10n.ok, action: onDismiss)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 380, maxWidth: 520, alignment: .leading)
        .frame(maxHeight: 640)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityIdentifier(presentation.sheetIdentifier)
        .interactiveDismissDisabled(onRetry != nil)
    }
}

#Preview {
    ErrorSheet(error: .sampleNotFound, onDismiss: {})
}

#Preview("빈 파일") {
    ErrorSheet(error: .emptyFile, onDismiss: {})
}

#Preview("선택한 파일") {
    ErrorSheet(error: .unsupportedType("notes.txt"), onDismiss: {})
}

#Preview("형식") {
    ErrorSheet(error: .unsupported, onDismiss: {})
}

#Preview("암호") {
    ErrorSheet(error: .encrypted, onDismiss: {})
}

#Preview("손상") {
    ErrorSheet(error: .corrupt, onDismiss: {})
}

#Preview("HWP 저장") {
    ErrorSheet(error: .saveRejected, onDismiss: {})
}

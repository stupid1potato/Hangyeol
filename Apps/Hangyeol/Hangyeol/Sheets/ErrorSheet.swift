import SwiftUI

struct ErrorSheet: View {
    let error: HangyeolError
    var title: String = L10n.errorTitle
    var retryTitle: String = L10n.retry
    var retryHint: String? = nil
    var onRetry: (() -> Void)? = nil
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            Text(error.localizedDescription)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .frame(minWidth: 380, maxWidth: 520)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(FailureSheetA11y.label(title: title, error: error))
        .accessibilityIdentifier("error-sheet")
        .interactiveDismissDisabled(onRetry != nil)
    }
}

#Preview {
    ErrorSheet(error: .sampleNotFound, onDismiss: {})
}

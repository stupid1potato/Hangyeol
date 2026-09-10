import SwiftUI

struct SaveFailureSheet: View {
    let error: HangyeolError
    var title: String = L10n.saveFailureTitle
    var retryTitle: String = L10n.retrySave
    var retryHint: String = L10n.saveFailureRetryHint
    var onRetry: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
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
                Button(L10n.cancel, action: onDismiss)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityHint(L10n.cancel)
                Button(retryTitle, action: onRetry)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint(retryHint)
            }
        }
        .padding(24)
        .frame(minWidth: 380, maxWidth: 520)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(FailureSheetA11y.label(title: title, error: error))
        .accessibilityIdentifier("save-failure-sheet")
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    SaveFailureSheet(
        error: .saveFailed("디스크가 가득 찼습니다."),
        onRetry: {},
        onDismiss: {}
    )
}

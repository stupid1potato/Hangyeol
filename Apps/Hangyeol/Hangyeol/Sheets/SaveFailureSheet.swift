import SwiftUI

struct SaveFailureSheet: View {
    let error: HangyeolError
    var context: ErrorSheetPresentation.Context = .save
    var title: String? = nil
    var retryTitle: String = L10n.retrySave
    var retryHint: String = L10n.saveFailureRetryHint
    var onRetry: () -> Void
    var onDismiss: () -> Void

    private var presentation: ErrorSheetPresentation {
        ErrorSheetPresentation.make(error: error, context: context, titleOverride: title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
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
                .accessibilityIdentifier("save-failure-cause")

            if let suggestion = presentation.nextAction {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.errorNextAction)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("save-failure-next-heading")
                    Text(suggestion)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("save-failure-next")
                }
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
        .frame(minWidth: 380, maxWidth: 520, alignment: .leading)
        .frame(maxHeight: 640)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityIdentifier(presentation.sheetIdentifier)
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

#Preview("HWP 저장 거절") {
    SaveFailureSheet(
        error: .saveRejected,
        onRetry: {},
        onDismiss: {}
    )
}

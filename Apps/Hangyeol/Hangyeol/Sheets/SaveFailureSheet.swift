import SwiftUI

struct SaveFailureSheet: View {
    let error: HangyeolError
    var onRetry: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
                Text(L10n.saveFailureTitle)
                    .font(.title2.weight(.semibold))
            }

            Text(error.localizedDescription)
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
                Button(L10n.retry, action: onRetry)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 380, maxWidth: 480)
    }
}

#Preview {
    SaveFailureSheet(
        error: .saveFailed("디스크가 가득 찼습니다."),
        onRetry: {},
        onDismiss: {}
    )
}

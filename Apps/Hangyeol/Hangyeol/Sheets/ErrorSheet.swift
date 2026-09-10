import SwiftUI

struct ErrorSheet: View {
    let error: HangyeolError
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                Text(L10n.errorTitle)
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
                Button(L10n.ok, action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 380, maxWidth: 480)
    }
}

#Preview {
    ErrorSheet(error: .sampleNotFound, onDismiss: {})
}

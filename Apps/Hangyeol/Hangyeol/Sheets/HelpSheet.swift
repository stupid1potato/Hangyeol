import SwiftUI

struct HelpSheet: View {
    var presentation: HelpPresentation = .make()
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(presentation.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("help-sheet-title")

                Text(presentation.body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("help-sheet-body")

                VStack(alignment: .leading, spacing: 8) {
                    Text(presentation.limitsTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("help-known-limits-title")

                    ForEach(presentation.limits) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("·")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            Text(item.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("help-limit-\(item.id)")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(HelpPresentation.limitsIdentifier)

                HStack {
                    Spacer()
                    Button(L10n.ok, action: onDismiss)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("help-sheet-ok")
                }
            }
            .padding(24)
            .frame(minWidth: 420, maxWidth: 560, alignment: .leading)
        }
        .frame(minWidth: 420, maxWidth: 560, maxHeight: 640)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityIdentifier(HelpPresentation.sheetIdentifier)
    }
}

#Preview {
    HelpSheet(onDismiss: {})
}

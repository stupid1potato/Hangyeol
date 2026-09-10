import SwiftUI

struct EmptyStateView: View {
    var recents: [RecentDocuments.Item] = []
    var onOpenSample: () -> Void
    var onOpenDocument: () -> Void
    var onOpenRecent: (RecentDocuments.Item) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(L10n.appName)
                    .font(.largeTitle.weight(.semibold))

                Text(L10n.appTagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.week1Note)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(action: onOpenSample) {
                        Text(L10n.openSample)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("o", modifiers: [.command, .shift])

                    Button(action: onOpenDocument) {
                        Text(L10n.openDocument)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(40)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.recents)
                    .font(.headline)
                if recents.isEmpty {
                    Text(L10n.recentsEmpty)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    ForEach(recents.prefix(8)) { item in
                        Button {
                            onOpenRecent(item)
                        } label: {
                            Label(item.title, systemImage: "doc")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(onOpenSample: {}, onOpenDocument: {})
}

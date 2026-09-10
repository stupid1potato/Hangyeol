import SwiftUI

struct EmptyStateView: View {
    var recents: [RecentDocuments.Item] = []
    var onOpenSample: () -> Void
    var onOpenDocument: () -> Void
    var onOpenRecent: (RecentDocuments.Item) -> Void = { _ in }

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 48

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(L10n.appName)
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(L10n.appTagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.week1Note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button(action: onOpenSample) {
                        Text(L10n.openSample)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                    .accessibilityHint(L10n.openSample)

                    Button(action: onOpenDocument) {
                        Text(L10n.openDocument)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint(L10n.openDocument)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(40)
            .accessibilityElement(children: .contain)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.recents)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if recents.isEmpty {
                    Text(L10n.recentsEmpty)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
                        .help(item.url.path)
                        .accessibilityLabel(item.title)
                        .accessibilityHint(L10n.recentsOpenHint)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)
            .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("empty-state")
    }
}

#Preview {
    EmptyStateView(onOpenSample: {}, onOpenDocument: {})
}

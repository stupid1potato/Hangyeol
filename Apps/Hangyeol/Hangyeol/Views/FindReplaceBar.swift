import SwiftUI

/// Mock에서는 스텁. Real(`KitRealEngine`) 세션이 있으면 바꾸기가 엔진 `replaceText`로 갑니다.
struct FindReplaceBar: View {
    @Binding var query: String
    @Binding var replacement: String
    var liveEngine: Bool = false
    var onFind: () -> Void = {}
    var onReplace: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(L10n.findPlaceholder, text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
                TextField(L10n.replacePlaceholder, text: $replacement)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
                Button(L10n.findNext, action: onFind)
                Button(L10n.replace, action: onReplace)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .help(L10n.close)
            }
            Text(liveEngine ? L10n.findLiveNote : L10n.findStubNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    FindReplaceBar(query: .constant("본문"), replacement: .constant(""))
}

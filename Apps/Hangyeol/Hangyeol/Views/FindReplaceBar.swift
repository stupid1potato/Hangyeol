import SwiftUI

/// 1주차 스텁. 찾기/바꾸기 UI만 제공하고 본문 검색은 이후 주차에서 연결합니다.
struct FindReplaceBar: View {
    @Binding var query: String
    @Binding var replacement: String
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
            Text(L10n.findStubNote)
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

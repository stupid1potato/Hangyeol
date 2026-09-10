import SwiftUI

struct StructuredTextView: View {
    let model: DocumentModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(model.blocks) { block in
                    switch block {
                    case .paragraph(let paragraph):
                        paragraphView(paragraph)
                    case .table(let table):
                        TableBlockView(table: table)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 880, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    @ViewBuilder
    private func paragraphView(_ paragraph: ParagraphBlock) -> some View {
        paragraph.runs.reduce(Text("")) { partial, run in
            var piece = Text(run.text)
            if run.isBold { piece = piece.bold() }
            if run.isItalic { piece = piece.italic() }
            return partial + piece
        }
        .font(.body)
        .lineSpacing(6)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    StructuredTextView(model: MockEngine.sampleDocument())
}

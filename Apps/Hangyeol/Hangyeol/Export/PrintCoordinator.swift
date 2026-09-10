import AppKit

/// 추출된 본문 텍스트를 시스템 인쇄 대화상자로 넘깁니다. WYSIWYG 조판이 아닙니다.
enum PrintCoordinator {
    @MainActor
    static func makePrintView(text: String, printInfo: NSPrintInfo) -> NSTextView {
        let view = NSTextView(frame: NSRect(
            x: 0,
            y: 0,
            width: max(printInfo.imageablePageBounds.width, 480),
            height: max(printInfo.imageablePageBounds.height, 640)
        ))
        view.string = text
        view.isEditable = false
        view.font = .systemFont(ofSize: 12)
        return view
    }

    @MainActor
    static func print(text: String, jobTitle: String) {
        let info = NSPrintInfo.shared
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic

        let view = makePrintView(text: text, printInfo: info)
        let operation = NSPrintOperation(view: view, printInfo: info)
        operation.jobTitle = jobTitle
        operation.showsPrintPanel = true
        operation.run()
    }

    @MainActor
    static func print(_ model: DocumentModel) {
        switch PrintFlow.prepare(isEmpty: model.isEmpty, plainText: model.plainText) {
        case .skippedEmpty:
            return
        case .ready(let text):
            print(text: text, jobTitle: model.displayTitle)
        }
    }
}

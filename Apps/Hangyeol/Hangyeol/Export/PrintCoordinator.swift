import AppKit

/// 1주차 스텁. 문서 레이아웃이 아니라 추출된 본문 텍스트만 인쇄 대화상자로 넘깁니다.
enum PrintCoordinator {
    @MainActor
    static func print(_ model: DocumentModel) {
        let info = NSPrintInfo.shared
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic

        let view = NSTextView(frame: NSRect(
            x: 0,
            y: 0,
            width: max(info.imageablePageBounds.width, 480),
            height: max(info.imageablePageBounds.height, 640)
        ))
        view.string = model.plainText.isEmpty ? L10n.printStub : model.plainText
        view.isEditable = false
        view.font = .systemFont(ofSize: 12)

        let operation = NSPrintOperation(view: view, printInfo: info)
        operation.jobTitle = model.displayTitle
        operation.showsPrintPanel = true
        operation.run()
    }
}

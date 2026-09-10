import AppKit
import Foundation

/// 1주차 스텁. WYSIWYG 레이아웃 없이 본문 텍스트만 PDF로 떨어뜨립니다.
enum PDFExporter {
    static func export(_ model: DocumentModel, to url: URL) throws {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        var mediaBox = page
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw HangyeolError.saveFailed(
                String(localized: "error.pdf.context", defaultValue: "PDF 파일을 만들 수 없습니다.")
            )
        }

        context.beginPDFPage(nil)

        let previous = NSGraphicsContext.current
        let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.current = nsContext

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.black
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        let body = model.plainText.isEmpty ? L10n.untitled : model.plainText

        (model.displayTitle as NSString).draw(
            in: CGRect(x: 54, y: 48, width: 504, height: 28),
            withAttributes: titleAttrs
        )
        (body as NSString).draw(
            in: CGRect(x: 54, y: 84, width: 504, height: 654),
            withAttributes: bodyAttrs
        )

        NSGraphicsContext.current = previous
        context.endPDFPage()
        context.closePDF()
    }
}

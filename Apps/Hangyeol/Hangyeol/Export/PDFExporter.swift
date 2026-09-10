import AppKit
import Foundation

/// 본문 텍스트를 PDF 페이지에 그립니다. WYSIWYG 조판이 아닙니다.
enum PDFExporter {
    static func export(_ model: DocumentModel, to url: URL) throws {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        var mediaBox = page
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw HangyeolError.exportFailed(
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

        (model.displayTitle as NSString).draw(
            in: CGRect(x: 54, y: 48, width: 504, height: 28),
            withAttributes: titleAttrs
        )
        (model.plainText as NSString).draw(
            in: CGRect(x: 54, y: 84, width: 504, height: 654),
            withAttributes: bodyAttrs
        )

        NSGraphicsContext.current = previous
        context.endPDFPage()
        context.closePDF()
    }
}

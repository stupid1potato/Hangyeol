import AppKit
import CoreText
import Foundation

/// 본문 텍스트(문단 + 표 셀 `plainText`)를 US Letter PDF로 보냅니다. WYSIWYG가 아닙니다.
enum PDFExporter {
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 54
    private static let titleHeight: CGFloat = 28
    private static let titleGap: CGFloat = 12

    static func export(_ model: DocumentModel, to url: URL) throws {
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let auxiliary = [kCGPDFContextTitle as String: model.displayTitle] as CFDictionary
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, auxiliary) else {
            throw HangyeolError.exportFailed(
                String(localized: "error.pdf.context", defaultValue: "PDF 파일을 만들 수 없습니다.")
            )
        }

        let titleFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
        let bodyFont = NSFont.systemFont(ofSize: 12)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: NSColor.black
        ]

        let contentWidth = pageWidth - margin * 2
        let body = NSAttributedString(string: model.plainText, attributes: bodyAttrs)
        let framesetter = CTFramesetterCreateWithAttributedString(body)
        var offset = 0
        let total = body.length
        var pageIndex = 0

        repeat {
            context.beginPDFPage(nil)

            if pageIndex == 0 {
                let title = NSAttributedString(string: model.displayTitle, attributes: titleAttrs)
                let titleLine = CTLineCreateWithAttributedString(title)
                context.textPosition = CGPoint(
                    x: margin,
                    y: pageHeight - margin - titleFont.ascender
                )
                CTLineDraw(titleLine, context)
            }

            let topInset: CGFloat = pageIndex == 0 ? margin + titleHeight + titleGap : margin
            let frameRect = CGRect(
                x: margin,
                y: margin,
                width: contentWidth,
                height: pageHeight - topInset - margin
            )
            let path = CGPath(rect: frameRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: offset, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)
            let visible = CTFrameGetVisibleStringRange(frame)
            if visible.length == 0 {
                offset = total
            } else {
                offset = visible.location + visible.length
            }

            context.endPDFPage()
            pageIndex += 1
        } while offset < total

        context.closePDF()
    }
}

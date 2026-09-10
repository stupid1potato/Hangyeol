import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var hangyeolHwpx: UTType {
        UTType(exportedAs: "org.hangyeol.hwpx")
    }

    static var hangyeolHwp: UTType {
        UTType(exportedAs: "org.hangyeol.hwp")
    }

    /// DocumentGroup / NSOpenPanel에 넘기는 한결 문서 UTI.
    static var hangyeolReadableTypes: [UTType] {
        [.hangyeolHwpx, .hangyeolHwp]
    }

    static func hangyeolSupports(url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "hwpx", "hwp":
            return true
        default:
            return false
        }
    }
}

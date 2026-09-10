import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var hangyeolHwpx: UTType {
        UTType(exportedAs: "org.hangyeol.hwpx")
    }

    static var hangyeolHwp: UTType {
        UTType(exportedAs: "org.hangyeol.hwp")
    }

    /// HWPX 타사 UTI (`UTImportedTypeDeclarations` / `LSItemContentTypes`).
    /// HOP가 `.hwpx` 확장자를 소유할 때 DocumentGroup이 거절하지 않게 한다.
    static let hangyeolImportedHwpxIdentifiers: [String] = [
        "net.golbin.hop.hwpx",
        "com.haansoft.HancomOfficeViewer.mac.hwpx",
    ]

    /// HWP 타사 UTI. Polaris 등 미확인 식별자는 런타임 확장자 바인딩으로 보완.
    static let hangyeolImportedHwpIdentifiers: [String] = [
        "net.golbin.hop.hwp",
        "com.haansoft.HancomOfficeViewer.mac.hwp",
    ]

    /// DocumentGroup / NSOpenPanel에 넘기는 한결 문서 UTI.
    /// `org.hangyeol.*` 가 기본. import한 한컴·HOP UTI와, 시스템이
    /// `.hwpx`/`.hwp` 에 바인딩한 그 밖의 UTI를 함께 포함한다.
    static var hangyeolReadableTypes: [UTType] {
        var types: [UTType] = [.hangyeolHwpx, .hangyeolHwp]
        var seen = Set(types.map(\.identifier))
        for identifier in hangyeolImportedHwpxIdentifiers + hangyeolImportedHwpIdentifiers {
            let imported = UTType(importedAs: identifier)
            if seen.insert(imported.identifier).inserted {
                types.append(imported)
            }
        }
        appendExtensionBoundTypes(for: "hwpx", into: &types, seen: &seen)
        appendExtensionBoundTypes(for: "hwp", into: &types, seen: &seen)
        return types
    }

    /// DocumentGroup/NSDocument가 넘긴 content type → 엔진 파일 종류.
    /// 경쟁 UTI·확장자 바인딩도 `.hwpx`/`.hwp` 로 매핑해 열기가 막히지 않게 한다.
    static func hangyeolFileType(from contentType: UTType) -> DocumentFileType {
        if hangyeolType(contentType, matchesExtension: "hwp") {
            return .hwp
        }
        return .hwpx
    }

    static func hangyeolSupports(url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "hwpx", "hwp":
            return true
        default:
            return false
        }
    }

    private static func hangyeolType(_ type: UTType, matchesExtension ext: String) -> Bool {
        let imported = ext == "hwp"
            ? hangyeolImportedHwpIdentifiers
            : hangyeolImportedHwpxIdentifiers
        let hangyeolID = ext == "hwp" ? hangyeolHwp.identifier : hangyeolHwpx.identifier
        if type.identifier == hangyeolID || imported.contains(type.identifier) {
            return true
        }
        if ext == "hwp", type.conforms(to: .hangyeolHwp) {
            return true
        }
        if ext == "hwpx", type.conforms(to: .hangyeolHwpx) {
            return true
        }
        if type.preferredFilenameExtension?.lowercased() == ext {
            return true
        }
        if type.tags[.filenameExtension]?.contains(where: { $0.lowercased() == ext }) == true {
            return true
        }
        if let bound = UTType(filenameExtension: ext), bound.identifier == type.identifier {
            return true
        }
        return false
    }

    private static func appendExtensionBoundTypes(
        for ext: String,
        into types: inout [UTType],
        seen: inout Set<String>
    ) {
        if let bound = UTType(filenameExtension: ext), seen.insert(bound.identifier).inserted {
            types.append(bound)
        }
        for extra in UTType.types(tag: ext, tagClass: .filenameExtension, conformingTo: nil) {
            if seen.insert(extra.identifier).inserted {
                types.append(extra)
            }
        }
    }
}

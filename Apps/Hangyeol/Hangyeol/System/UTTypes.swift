import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var hangyeolHwpx: UTType {
        UTType(exportedAs: "org.hangyeol.hwpx")
    }

    static var hangyeolHwp: UTType {
        UTType(exportedAs: "org.hangyeol.hwp")
    }

    /// Info.plist `UTImportedTypeDeclarations` / `LSItemContentTypes` HWPX.
    /// 필수 최소셋은 `net.golbin.hop.hwpx` (Mac에서 `.hwpx` 확장자 바인딩).
    static let hangyeolImportedHwpxIdentifiers: [String] = [
        "net.golbin.hop.hwpx",
        "com.haansoft.HancomOfficeViewer.mac.hwpx",
    ]

    /// Info.plist imported HWP. 필수 최소셋 `net.golbin.hop.hwp`. Polaris는 lookup 유지.
    static let hangyeolImportedHwpIdentifiers: [String] = [
        "net.golbin.hop.hwp",
        "com.infraware.polarisofficeservice.hwp",
        "com.haansoft.HancomOfficeViewer.mac.hwp",
    ]

    /// Info.plist imported 전체. haansoft는 plist에만 두고 readable 테스트는 stable 셋을 본다.
    static var hangyeolImportedTypeIdentifiers: [String] {
        hangyeolImportedHwpxIdentifiers + hangyeolImportedHwpIdentifiers
    }

    /// `UTType(id)` / `importedAs` 가 원본 문자열을 보존하는 경쟁 UTI (GUI 성공 최소셋).
    /// haansoft는 `importedAs` 가 HOP로 흡수되고, `UTType(id)` 는 소문자화된다.
    static let hangyeolStableImportedIdentifiers: [String] = [
        "net.golbin.hop.hwpx",
        "net.golbin.hop.hwp",
        "com.infraware.polarisofficeservice.hwp",
    ]

    /// DocumentGroup / NSOpenPanel에 넘기는 한결 문서 UTI.
    static var hangyeolReadableTypes: [UTType] {
        var types: [UTType] = []
        var seen = Set<String>()
        let declared = [hangyeolHwpx.identifier, hangyeolHwp.identifier]
            + hangyeolImportedTypeIdentifiers
        for identifier in declared {
            let type = resolvedReadableType(for: identifier)
            if seen.insert(type.identifier).inserted {
                types.append(type)
            }
        }
        appendExtensionBoundTypes(for: "hwpx", into: &types, seen: &seen)
        appendExtensionBoundTypes(for: "hwp", into: &types, seen: &seen)
        return types
    }

    /// DocumentGroup/NSDocument가 넘긴 content type → 엔진 파일 종류.
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

    static func hangyeolImportedIdentifier(_ identifier: String, matches candidates: [String]) -> Bool {
        candidates.contains { $0.caseInsensitiveCompare(identifier) == .orderedSame }
    }

    /// `UTType(id)` 를 먼저 쓴다. nil이면 `importedAs`.
    /// haansoft `importedAs` 는 확장자 태그로 HOP에 흡수된다.
    static func resolvedReadableType(for identifier: String) -> UTType {
        if identifier == hangyeolHwpx.identifier {
            return .hangyeolHwpx
        }
        if identifier == hangyeolHwp.identifier {
            return .hangyeolHwp
        }
        return UTType(identifier) ?? UTType(importedAs: identifier)
    }

    private static func hangyeolType(_ type: UTType, matchesExtension ext: String) -> Bool {
        let imported = ext == "hwp"
            ? hangyeolImportedHwpIdentifiers
            : hangyeolImportedHwpxIdentifiers
        let hangyeolID = ext == "hwp" ? hangyeolHwp.identifier : hangyeolHwpx.identifier
        if type.identifier == hangyeolID || hangyeolImportedIdentifier(type.identifier, matches: imported) {
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

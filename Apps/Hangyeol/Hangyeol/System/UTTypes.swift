import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var hangyeolHwpx: UTType {
        UTType(exportedAs: "org.hangyeol.hwpx")
    }

    static var hangyeolHwp: UTType {
        UTType(exportedAs: "org.hangyeol.hwp")
    }

    /// 필수 최소셋: Mac에서 `UTType(filenameExtension:)` 가 HOP.app export 로 해석한 식별자.
    /// `net.golbin.hop.hwpx` desc = Hangul Word Processor XML document.
    static let hangyeolImportedHwpxIdentifiers: [String] = [
        "net.golbin.hop.hwpx",
        "com.haansoft.HancomOfficeViewer.mac.hwpx",
    ]

    /// 필수 최소셋 `net.golbin.hop.hwp`. Polaris는 Mac에서 lookup 됨.
    /// `com.hancom.*` / `com.haansoft.*` 는 한컴 미설치 Mac에서 MISSING — import는 무해.
    static let hangyeolImportedHwpIdentifiers: [String] = [
        "net.golbin.hop.hwp",
        "com.infraware.polarisofficeservice.hwp",
        "com.haansoft.HancomOfficeViewer.mac.hwp",
    ]

    /// Info.plist `UTImportedTypeDeclarations` 와 동일 소스.
    static var hangyeolImportedTypeIdentifiers: [String] {
        hangyeolImportedHwpxIdentifiers + hangyeolImportedHwpIdentifiers
    }

    /// DocumentGroup이 받아야 하는 선언 식별자 (export + import). 확장자 바인딩은 런타임 추가.
    static var hangyeolDeclaredReadableIdentifiers: [String] {
        var ids = [hangyeolHwpx.identifier, hangyeolHwp.identifier]
        var seen = Set(ids)
        for id in hangyeolImportedTypeIdentifiers where seen.insert(id).inserted {
            ids.append(id)
        }
        return ids
    }

    /// DocumentGroup / NSOpenPanel에 넘기는 한결 문서 UTI.
    /// `org.hangyeol.*` 가 기본. import 식별자는 한컴 미설치여도 항상 포함한다.
    static var hangyeolReadableTypes: [UTType] {
        var types: [UTType] = []
        var seen = Set<String>()
        for identifier in hangyeolDeclaredReadableIdentifiers {
            let type = declaredImportedType(identifier)
            guard seen.insert(identifier).inserted else { continue }
            types.append(type)
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

    /// Lookup이 HOP 등으로 합쳐지거나 nil이어도, 요청한 identifier를 가진 UTType을 만든다.
    static func declaredImportedType(_ identifier: String) -> UTType {
        if identifier == hangyeolHwpx.identifier {
            return .hangyeolHwpx
        }
        if identifier == hangyeolHwp.identifier {
            return .hangyeolHwp
        }
        if let known = UTType(identifier), known.identifier == identifier {
            return known
        }
        let withSupertype = UTType(importedAs: identifier, conformingTo: .data)
        if withSupertype.identifier == identifier {
            return withSupertype
        }
        let imported = UTType(importedAs: identifier)
        if imported.identifier == identifier {
            return imported
        }
        if let decoded = try? JSONDecoder().decode(
            UTType.self,
            from: Data("\"\(identifier)\"".utf8)
        ), decoded.identifier == identifier {
            return decoded
        }
        return withSupertype
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

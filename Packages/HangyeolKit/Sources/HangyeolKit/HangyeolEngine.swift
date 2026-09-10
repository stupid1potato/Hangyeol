import Foundation

/// Kit-local file type. Mirrors `Apps/Hangyeol` `DocumentFileType` without sharing types.
/// Apps/Hangyeol must not import HangyeolKit (MockEngine stays live; no RealEngine
/// until an XCFramework of `engine/` exists).
public enum DocumentFileType: String, Sendable, Codable, CaseIterable {
    case hwpx
    case hwp
}

/// Placeholder document payload. Not the app `DocumentModel`.
/// Future mapping (not in this package): rhwp DocumentCore IR via the thin `hg_*`
/// cdylib in `engine/` (rustc ≥ 1.88), once that cdylib is shipped as an XCFramework.
/// This package does not link `engine/` and does not call the real cdylib.
public struct DocumentModel: Sendable, Equatable {
    public var fileType: DocumentFileType

    public init(fileType: DocumentFileType) {
        self.fileType = fileType
    }
}

/// Same boundary as the app `HangyeolEngine` protocol (`open` / `save`).
/// Freeze edit ABI (`hg_plain_text` / `hg_replace_text` / `hg_save_hwpx` /
/// `hg_insert_text` / `hg_delete_range` / `hg_last_error`) lives on
/// `HangyeolEngineFFI` as declarations that still throw `notLinked`.
/// The app keeps its own protocol and `MockEngine`; this type is not wired in.
public protocol HangyeolEngine: Sendable {
    func open(data: Data, type: DocumentFileType) throws -> DocumentModel
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data
}

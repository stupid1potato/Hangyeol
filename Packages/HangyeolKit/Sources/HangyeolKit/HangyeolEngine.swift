import Foundation

/// Kit-local file type. Mirrors `Apps/Hangyeol` `DocumentFileType` without sharing types.
/// Apps/Hangyeol must not import HangyeolKit (MockEngine stays live; no RealEngine).
public enum DocumentFileType: String, Sendable, Codable, CaseIterable {
    case hwpx
    case hwp
}

/// Placeholder document payload. Not the app `DocumentModel`.
/// Future mapping (not in this package): rhwp DocumentCore IR via thin `hg_*` cdylib
/// (rustc ≥ 1.88). No implementation until that cdylib exists.
public struct DocumentModel: Sendable, Equatable {
    public var fileType: DocumentFileType

    public init(fileType: DocumentFileType) {
        self.fileType = fileType
    }
}

/// Same boundary as the app `HangyeolEngine` protocol. The app keeps its own
/// protocol and `MockEngine`. This type exists so HangyeolKit can compile in isolation;
/// it is not wired into the app.
public protocol HangyeolEngine: Sendable {
    func open(data: Data, type: DocumentFileType) throws -> DocumentModel
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data
}

import Foundation

/// Kit-local file type. Mirrors `Apps/Hangyeol` `DocumentFileType` without sharing types
/// (importing this package from the app would create a premature engine link).
public enum DocumentFileType: String, Sendable, Codable, CaseIterable {
    case hwpx
    case hwp
}

/// Placeholder document payload. Not the app `DocumentModel`; week 3 RealEngine
/// will replace this with a mapping from the C ABI / engine IR.
public struct DocumentModel: Sendable, Equatable {
    public var fileType: DocumentFileType

    public init(fileType: DocumentFileType) {
        self.fileType = fileType
    }
}

/// Same boundary as the app `HangyeolEngine` protocol. The app keeps its own
/// protocol and `MockEngine`; this type exists so HangyeolKit can compile in isolation.
public protocol HangyeolEngine: Sendable {
    func open(data: Data, type: DocumentFileType) throws -> DocumentModel
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data
}

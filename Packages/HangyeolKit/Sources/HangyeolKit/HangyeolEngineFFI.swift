import CHangyeolEngine
import Foundation

/// Four status kinds, matching `hg_status` in `hangyeol_engine.h`.
public enum HangyeolStatus: Int32, Sendable, Equatable {
    case ok = 0
    case unsupported = 1
    case corrupt = 2
    case password = 3

    public init(cStatus: hg_status) {
        self = HangyeolStatus(rawValue: Int32(cStatus.rawValue)) ?? .unsupported
    }
}

public enum HangyeolKitError: Error, Sendable, Equatable {
    /// rhwp `hg_*` cdylib / XCFramework is not linked. Apps/Hangyeol must keep `MockEngine`.
    case notLinked
    /// Draft symbol is not implemented (개발자1 thin cdylib 대기).
    case unimplemented
    case status(HangyeolStatus)
}

/// Thin FFI façade over the C stub. Always throws `notLinked`.
/// Not a RealEngine: no app link, no live `hg_*` calls until 개발자1 cdylib.
/// Product save (when implemented there) must clear lineseg / `hp:linesegarray` first.
public struct HangyeolEngineFFI: HangyeolEngine {
    public init() {}

    public func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        var engine: OpaquePointer?
        _ = data.withUnsafeBytes { raw -> hg_status in
            let bytes = raw.bindMemory(to: UInt8.self)
            return hg_open(bytes.baseAddress, bytes.count, type.hgFileType, &engine)
        }
        defer { hg_close(engine) }
        throw HangyeolKitError.notLinked
    }

    /// Stub only. Real `hg_save` (DocumentCore cdylib) must lineseg-clear before write.
    public func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        _ = model
        var outBytes: UnsafeMutablePointer<UInt8>?
        var outLength = 0
        _ = withUnsafeMutablePointer(to: &outBytes) { bytesPtr in
            hg_save(nil, type.hgFileType, bytesPtr, &outLength)
        }
        hg_free_buffer(outBytes)
        throw HangyeolKitError.notLinked
    }
}

extension DocumentFileType {
    var hgFileType: hg_file_type {
        switch self {
        case .hwpx:
            return HG_FILE_HWPX
        case .hwp:
            return HG_FILE_HWP
        }
    }
}

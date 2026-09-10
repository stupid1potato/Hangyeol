import CHangyeolEngine
import Foundation

/// Four status kinds, matching `hg_status` in `hangyeol_engine.h`
/// (synced from `engine/include/hangyeol_engine.h`, source of truth).
///
/// Freeze string codes ↔ Kit `hg_status` (1:1):
///   `ENCRYPTED`            ↔ `HG_PASSWORD` / `.password`
///   `UNSUPPORTED_VERSION`  ↔ `HG_UNSUPPORTED` / `.unsupported`
///   `SAVE_REJECTED`        ↔ `HG_UNSUPPORTED` / `.unsupported`
///   `CORRUPT`              ↔ `HG_CORRUPT` / `.corrupt`
///
/// F16 truncated/unknown is CORRUPT, not a vague unsupported passthrough.
public enum HangyeolStatus: Int32, Sendable, Equatable {
    case ok = 0
    case unsupported = 1
    case corrupt = 2
    case password = 3

    public init(cStatus: hg_status) {
        self = HangyeolStatus(rawValue: Int32(cStatus.rawValue)) ?? .unsupported
    }
}

/// Freeze `hg_last_error` string codes from the engine ABI.
/// The C stub returns NULL; the real cdylib is not linked from this package.
public enum HangyeolFreezeCode: String, Sendable, Equatable {
    case unsupportedVersion = "UNSUPPORTED_VERSION"
    case encrypted = "ENCRYPTED"
    case corrupt = "CORRUPT"
    case saveRejected = "SAVE_REJECTED"
}

public enum HangyeolKitError: Error, Sendable, Equatable {
    /// rhwp `hg_*` XCFramework is not linked. Apps/Hangyeol must keep `MockEngine`.
    case notLinked
    /// Symbol is declared for ABI coverage; C stub returns `HG_UNSUPPORTED`.
    case unimplemented
    case status(HangyeolStatus)
}

/// Thin FFI façade over the C stub. Always throws `notLinked`.
/// Not a RealEngine: no app link, no live calls into the Rust `engine/` cdylib.
/// RealEngine waits for an XCFramework path; Mock stays until then.
///
/// Product save (when the XCFramework is linked) must clear every paragraph
/// and table-cell `line_segs` before serialize (`hp:linesegarray` count 0).
/// Kit `hg_save(HWPX)` and freeze `hg_save_hwpx` are that same path.
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
    /// HWP (`HG_FILE_HWP`) is freeze `SAVE_REJECTED` / `HG_UNSUPPORTED` (HWPX-only write).
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

    /// Freeze `hg_plain_text`: concatenate body + table-cell paragraph text (UTF-8).
    /// C stub returns `HG_UNSUPPORTED`; Swift throws `notLinked`.
    public func plainText() throws -> Data {
        var outBytes: UnsafeMutablePointer<UInt8>?
        var outLength = 0
        _ = hg_plain_text(nil, &outBytes, &outLength)
        hg_free_buffer(outBytes)
        throw HangyeolKitError.notLinked
    }

    /// Freeze `hg_replace_text`: `replace_all_native` including table cells.
    /// C stub returns `HG_UNSUPPORTED`; Swift throws `notLinked`.
    public func replaceText(find: String, replace: String) throws -> Int {
        var count = 0
        _ = find.withCString { findPtr in
            replace.withCString { replacePtr in
                hg_replace_text(nil, findPtr, replacePtr, &count)
            }
        }
        throw HangyeolKitError.notLinked
    }

    /// Freeze `hg_save_hwpx`: write HWPX to a UTF-8 filesystem path.
    /// Same clear-before-save as Kit `hg_save(..., HG_FILE_HWPX, ...)`.
    /// C stub returns `HG_UNSUPPORTED`; Swift throws `notLinked`.
    public func saveHwpx(to path: String) throws {
        _ = path.withCString { hg_save_hwpx(nil, $0) }
        throw HangyeolKitError.notLinked
    }

    /// Optional freeze `hg_insert_text` at (section, paragraph, char_offset).
    /// C stub returns `HG_UNSUPPORTED`; Swift throws `notLinked`.
    public func insertText(
        section: UInt32,
        paragraph: UInt32,
        charOffset: UInt32,
        text: String
    ) throws {
        _ = text.withCString { hg_insert_text(nil, section, paragraph, charOffset, $0) }
        throw HangyeolKitError.notLinked
    }

    /// Optional freeze `hg_delete_range` of `count` characters at the same index.
    /// C stub returns `HG_UNSUPPORTED`; Swift throws `notLinked`.
    public func deleteRange(
        section: UInt32,
        paragraph: UInt32,
        charOffset: UInt32,
        count: UInt32
    ) throws {
        _ = hg_delete_range(nil, section, paragraph, charOffset, count)
        throw HangyeolKitError.notLinked
    }

    /// Freeze `hg_last_error`: thread-local string code, or `nil` after success.
    /// C stub returns NULL (`"UNSUPPORTED_VERSION"` | `"ENCRYPTED"` | `"CORRUPT"` |
    /// `"SAVE_REJECTED"` on the real engine).
    public static func lastError() -> String? {
        guard let pointer = hg_last_error() else { return nil }
        return String(cString: pointer)
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

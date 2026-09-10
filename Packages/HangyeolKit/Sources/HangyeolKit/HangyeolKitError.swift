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
public enum HangyeolFreezeCode: String, Sendable, Equatable {
    case unsupportedVersion = "UNSUPPORTED_VERSION"
    case encrypted = "ENCRYPTED"
    case corrupt = "CORRUPT"
    case saveRejected = "SAVE_REJECTED"

    /// Freeze ↔ Kit mapping used by `RealEngine`.
    public var kitStatus: HangyeolStatus {
        switch self {
        case .encrypted:
            return .password
        case .unsupportedVersion, .saveRejected:
            return .unsupported
        case .corrupt:
            return .corrupt
        }
    }
}

public enum HangyeolKitError: Error, Sendable, Equatable {
    /// C stub is compiled in; `HangyeolEngine.xcframework` is not linked.
    /// `RealEngine` never throws this when `HANGYEOL_ENGINE_LINKED` is set.
    case notLinked
    /// Symbol is declared for ABI coverage; C stub returns `HG_UNSUPPORTED`.
    /// `HangyeolEngineFFI` uses this when the XCFramework is linked (use `RealEngine`).
    case unimplemented
    /// Non-OK `hg_status`, with freeze `hg_last_error` when the engine set one.
    case status(HangyeolStatus, freeze: HangyeolFreezeCode?)

    public static func status(_ status: HangyeolStatus) -> HangyeolKitError {
        .status(status, freeze: nil)
    }

    /// Map `hg_status` + `hg_last_error` onto Kit errors.
    ///
    /// When the real library is linked (`engineLinked == true`), this never
    /// returns `notLinked`. When the stub is compiled in, a failure with no
    /// freeze code is `notLinked` (the stub returns `HG_UNSUPPORTED` / NULL).
    public static func from(status: HangyeolStatus, lastError: String?, engineLinked: Bool) -> HangyeolKitError? {
        guard status != .ok else { return nil }
        let freeze = lastError.flatMap(HangyeolFreezeCode.init(rawValue:))
        if !engineLinked && freeze == nil {
            return .notLinked
        }
        let mapped = freeze?.kitStatus ?? status
        return .status(mapped, freeze: freeze)
    }
}

enum HangyeolEngineSupport {
    static var isLinked: Bool {
        #if HANGYEOL_ENGINE_LINKED
        true
        #else
        false
        #endif
    }

    static func lastErrorString() -> String? {
        guard let pointer = hg_last_error() else { return nil }
        return String(cString: pointer)
    }

    static func throwIfNeeded(_ status: hg_status) throws {
        let mapped = HangyeolStatus(cStatus: status)
        if let error = HangyeolKitError.from(
            status: mapped,
            lastError: lastErrorString(),
            engineLinked: isLinked
        ) {
            throw error
        }
    }

    static func takeBuffer(
        status: hg_status,
        bytes: UnsafeMutablePointer<UInt8>?,
        length: Int
    ) throws -> Data {
        defer { hg_free_buffer(bytes) }
        try throwIfNeeded(status)
        guard let bytes, length > 0 else { return Data() }
        return Data(bytes: bytes, count: length)
    }

    /// Zero-fill a C struct (used for `hg_image_info` fixed `char[]` fields).
    static func zeroedCStruct<T>() -> T {
        withUnsafeTemporaryAllocation(
            byteCount: MemoryLayout<T>.size,
            alignment: MemoryLayout<T>.alignment
        ) { buf in
            buf.initializeMemory(as: UInt8.self, repeating: 0)
            return buf.load(as: T.self)
        }
    }

    /// NUL-terminated C `char[]` imported as a Swift tuple.
    static func cString<T>(from tuple: T) -> String {
        withUnsafeBytes(of: tuple) { raw in
            guard let base = raw.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                return ""
            }
            return String(cString: base)
        }
    }
}

extension TableInfo {
    init(_ info: hg_table_info) {
        self.init(
            index: info.index,
            section: info.section,
            paragraph: info.paragraph,
            control: info.control,
            rows: info.rows,
            cols: info.cols
        )
    }
}

extension ImageInfo {
    init(_ info: hg_image_info) {
        self.init(
            index: info.index,
            section: info.section,
            paragraph: info.paragraph,
            control: info.control,
            width: info.width,
            height: info.height,
            byteLen: info.byte_len,
            binDataId: info.bin_data_id,
            format: HangyeolEngineSupport.cString(from: info.format),
            href: HangyeolEngineSupport.cString(from: info.href)
        )
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

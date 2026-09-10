import Foundation

/// 문서 엔진 경계. 기본값은 XCFramework가 연결된 Real(`KitRealEngine`);
/// 없으면 `MockEngine`. `resetToMock()`과 `HANGYEOL_USE_MOCK`으로 롤백 가능.
protocol HangyeolEngine: Sendable {
    func open(data: Data, type: DocumentFileType) throws -> DocumentModel
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data
}

/// Live DocumentCore session extras (Kit `RealEngine` via `KitRealEngine`).
protocol HangyeolLiveSession: HangyeolEngine {
    func replaceText(find: String, replace: String) throws -> Int
    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel
    func saveHwpx(to path: String) throws
}

enum EngineClient {
    /// Launch env and UserDefaults key. `1` / `true` / `YES` force Mock.
    static let useMockFlagKey = "HANGYEOL_USE_MOCK"

    private static let holder = Holder()

    static var current: any HangyeolEngine {
        get { holder.engine }
        set { holder.engine = newValue }
    }

    static var isUsingMock: Bool { current is MockEngine }

    static var liveSession: (any HangyeolLiveSession)? {
        current as? any HangyeolLiveSession
    }

    /// Process-level rollback. Does not persist UserDefaults.
    static func resetToMock() {
        current = MockEngine()
    }

    static func resetToDefault() {
        current = makeDefaultEngine()
    }

    static var prefersMock: Bool {
        if environmentForcesMock { return true }
        return UserDefaults.standard.bool(forKey: useMockFlagKey)
    }

    static var environmentForcesMock: Bool {
        guard let raw = ProcessInfo.processInfo.environment[useMockFlagKey] else {
            return false
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value == "1" || value == "true" || value == "yes"
    }

    /// Default: Real when the XCFramework is linked and Mock is not forced; else Mock.
    static func makeDefaultEngine() -> any HangyeolEngine {
        if prefersMock {
            return MockEngine()
        }
        if KitRealEngine.isAvailable {
            return KitRealEngine()
        }
        return MockEngine()
    }

    /// Smoke / find-replace: Kit `replaceText` on the open session.
    static func replaceText(find: String, replace: String) throws -> Int {
        guard let session = liveSession else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.replaceMock",
                defaultValue: "찾기/바꾸기 (Mock)"
            ))
        }
        return try session.replaceText(find: find, replace: replace)
    }

    static func refreshDisplayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        guard let session = liveSession else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.replaceMock",
                defaultValue: "찾기/바꾸기 (Mock)"
            ))
        }
        return try session.displayModel(type: type, title: title)
    }

    static func saveHwpx(to path: String) throws {
        guard let session = liveSession else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.saveHwpxMock",
                defaultValue: "HWPX 엔진 저장 (Mock)"
            ))
        }
        try session.saveHwpx(to: path)
    }

    private final class Holder: @unchecked Sendable {
        private let lock = NSLock()
        private var _engine: any HangyeolEngine = EngineClient.makeDefaultEngine()

        var engine: any HangyeolEngine {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _engine
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                _engine = newValue
            }
        }
    }
}

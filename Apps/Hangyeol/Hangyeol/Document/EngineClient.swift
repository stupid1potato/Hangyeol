import Foundation

/// 문서 엔진 경계. 1주차는 `MockEngine`, 이후 FFI 구현으로 교체합니다.
protocol HangyeolEngine: Sendable {
    func open(data: Data, type: DocumentFileType) throws -> DocumentModel
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data
}

enum EngineClient {
    private static let holder = Holder()

    static var current: any HangyeolEngine {
        get { holder.engine }
        set { holder.engine = newValue }
    }

    static func resetToMock() {
        current = MockEngine()
    }

    private final class Holder: @unchecked Sendable {
        private let lock = NSLock()
        private var _engine: any HangyeolEngine = MockEngine()

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

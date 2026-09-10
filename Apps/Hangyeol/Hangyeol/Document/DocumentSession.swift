import Combine
import Foundation

/// One engine instance bound to a single open document/window for its lifetime.
///
/// `HangyeolDocument` is a FileDocument value (copied by DocumentGroup). This
/// class is the identity of that copy-set: two windows each own a session, so
/// `KitRealEngine` / `hg_engine*` is not the process-wide `EngineClient.current`
/// singleton (PR #16 clobber).
///
/// Frontend: observe `lastSaveError` / `lastOpenError` (or catch throws) to
/// present sheets. This type does not present UI.
final class DocumentSession: ObservableObject, Identifiable, @unchecked Sendable {
    let id: UUID

    private let lock = NSLock()
    private var engine: any HangyeolEngine

    /// Last mapped save failure. Cleared on the next successful save.
    @Published private(set) var lastSaveError: HangyeolError?
    /// Last mapped open failure. Cleared on the next successful open.
    @Published private(set) var lastOpenError: HangyeolError?

    init(engine: any HangyeolEngine = EngineClient.makeEngine()) {
        self.id = UUID()
        self.engine = engine
    }

    var isUsingMock: Bool {
        lock.lock()
        defer { lock.unlock() }
        return engine is MockEngine
    }

    var liveSession: (any HangyeolLiveSession)? {
        lock.lock()
        defer { lock.unlock() }
        return engine as? any HangyeolLiveSession
    }

    var isOpen: Bool {
        lock.lock()
        defer { lock.unlock() }
        if let live = engine as? any HangyeolLiveSession {
            return live.isOpen
        }
        return engine is MockEngine
    }

    /// Real session with an open `hg_engine*` (find/replace / live HWPX save).
    var canReplace: Bool {
        lock.lock()
        defer { lock.unlock() }
        return (engine as? any HangyeolLiveSession)?.isOpen == true
    }

    func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        do {
            lastOpenError = nil
            return try withEngine { engine in
                do {
                    return try engine.open(data: data, type: type)
                } catch {
                    guard engine is KitRealEngine, Self.looksLikeMockJSON(data) else {
                        throw error
                    }
                    // Mock JSON .hwpx (untitled save / bundled sample) while
                    // the factory default is Real: bind this document to Mock.
                    let mock = MockEngine()
                    self.engine = mock
                    return try mock.open(data: data, type: type)
                }
            }
        } catch let error as HangyeolError {
            lastOpenError = error
            throw error
        } catch {
            let mapped = HangyeolError.mapOpenFailure(error)
            lastOpenError = mapped
            throw mapped
        }
    }

    /// Persist this session's IR (Real) or Mock JSON. Never uses `EngineClient.current`.
    /// HWP write is always `saveRejected` (engine freeze SAVE_REJECTED).
    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        if type == .hwp {
            let error = HangyeolError.saveRejected
            lastSaveError = error
            throw error
        }
        do {
            lastSaveError = nil
            return try withEngine { engine in
                if let live = engine as? any HangyeolLiveSession, !live.isOpen {
                    // Untitled Real has no DocumentCore IR yet; Mock JSON so
                    // Save As .hwpx still round-trips. Not a re-encode of live IR.
                    self.engine = MockEngine()
                    return try self.engine.save(model, as: type)
                }
                return try engine.save(model, as: type)
            }
        } catch {
            let mapped = HangyeolError.mapSaveFailure(error)
            lastSaveError = mapped
            throw mapped
        }
    }

    func replaceText(find: String, replace: String) throws -> Int {
        guard let session = liveSession, session.isOpen else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.replaceMock",
                defaultValue: "찾기/바꾸기 (Mock)"
            ))
        }
        return try session.replaceText(find: find, replace: replace)
    }

    func displayModel(type: DocumentFileType, title: String) throws -> DocumentModel {
        guard let session = liveSession, session.isOpen else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.replaceMock",
                defaultValue: "찾기/바꾸기 (Mock)"
            ))
        }
        return try session.displayModel(type: type, title: title)
    }

    func saveHwpx(to path: String) throws {
        guard let session = liveSession, session.isOpen else {
            throw HangyeolError.notYetImplemented(String(
                localized: "error.engine.saveHwpxMock",
                defaultValue: "HWPX 엔진 저장 (Mock)"
            ))
        }
        do {
            lastSaveError = nil
            try session.saveHwpx(to: path)
        } catch let error as HangyeolError {
            let mapped = HangyeolError.mapSaveFailure(error)
            lastSaveError = mapped
            throw mapped
        } catch {
            let mapped = HangyeolError.mapSaveFailure(error)
            lastSaveError = mapped
            throw mapped
        }
    }

    private func withEngine<T>(_ body: (any HangyeolEngine) throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(engine)
    }

    /// App JSON snapshots written by Mock / untitled-without-IR.
    private static func looksLikeMockJSON(_ data: Data) -> Bool {
        (try? JSONDecoder().decode(DocumentModel.self, from: data)) != nil
    }
}

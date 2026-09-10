import Foundation
import HangyeolKit

/// App-side adapter: Kit `RealEngine` (live `hg_engine*` / DocumentCore IR)
/// → app `HangyeolEngine` / `DocumentModel` (blocks / paragraphs).
///
/// Kit `HangyeolKit.DocumentModel` is only a file-type placeholder. Display
/// uses UTF-8 `plainText()` mapped to paragraphs (table cells are flattened
/// into the same newline stream — best-effort / plain for week-3).
///
/// `save` calls Kit `save` / `saveHwpx` on the **live session**, not a
/// re-encode of app JSON as HWPX.
final class KitRealEngine: HangyeolLiveSession, @unchecked Sendable {
    static var isAvailable: Bool { HangyeolKit.RealEngine.isLinked }

    private let kit = HangyeolKit.RealEngine()

    var isOpen: Bool { kit.isOpen }

    func open(data: Data, type: Hangyeol.DocumentFileType) throws -> Hangyeol.DocumentModel {
        do {
            _ = try kit.open(data: data, type: kitFileType(type))
            return try displayModel(type: type, title: "")
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Persist DocumentCore IR. `model` is the UI snapshot and is not serialized.
    func save(_ model: Hangyeol.DocumentModel, as type: Hangyeol.DocumentFileType) throws -> Data {
        _ = model
        let kitType = kitFileType(type)
        do {
            return try kit.save(HangyeolKit.DocumentModel(fileType: kitType), as: kitType)
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Freeze `hg_replace_text` on the open session (body + table cells).
    func replaceText(find: String, replace: String) throws -> Int {
        do {
            return try kit.replaceText(find: find, replace: replace)
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Re-read UTF-8 plain text from the live session into app paragraphs.
    func displayModel(type: Hangyeol.DocumentFileType, title: String) throws -> Hangyeol.DocumentModel {
        do {
            let bytes = try kit.plainText()
            let text = String(data: bytes, encoding: .utf8) ?? ""
            return Self.documentModel(fromPlainText: text, type: type, title: title)
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Freeze `hg_save_hwpx` (same clear-before-save as Kit `save` HWPX).
    func saveHwpx(to path: String) throws {
        do {
            try kit.saveHwpx(to: path)
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Kit concatenates body + table-cell paragraphs with `\n`.
    static func documentModel(
        fromPlainText text: String,
        type: Hangyeol.DocumentFileType,
        title: String = ""
    ) -> Hangyeol.DocumentModel {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let blocks: [ContentBlock]
        if lines.isEmpty {
            // Keep a single empty paragraph so an open session is not treated as EmptyState.
            blocks = [.paragraph(ParagraphBlock(text: ""))]
        } else {
            blocks = lines.map { .paragraph(ParagraphBlock(text: $0)) }
        }
        return Hangyeol.DocumentModel(
            metadata: DocumentMetadata(title: title, sourceType: type),
            blocks: blocks
        )
    }

    static func mapError(_ error: Error) -> HangyeolError {
        guard let kitError = error as? HangyeolKitError else {
            return .engineFailed(error.localizedDescription)
        }
        switch kitError {
        case .notLinked:
            return .engineFailed(String(
                localized: "error.engine.notLinked",
                defaultValue: "HangyeolEngine XCFramework가 연결되지 않았습니다."
            ))
        case .unimplemented:
            return .notYetImplemented(String(
                localized: "error.engine.unimplemented",
                defaultValue: "엔진 기능"
            ))
        case .status(let status, let freeze):
            let code = freeze?.rawValue
            switch status {
            case .ok:
                return .engineFailed(code ?? error.localizedDescription)
            case .unsupported:
                return .engineFailed(code ?? "UNSUPPORTED")
            case .corrupt:
                return .engineFailed(code ?? "CORRUPT")
            case .password:
                return .engineFailed(code ?? "ENCRYPTED")
            }
        }
    }

    private func kitFileType(_ type: Hangyeol.DocumentFileType) -> HangyeolKit.DocumentFileType {
        switch type {
        case .hwpx: return .hwpx
        case .hwp: return .hwp
        }
    }
}

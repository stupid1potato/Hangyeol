import SwiftUI
import UniformTypeIdentifiers

struct HangyeolDocument: FileDocument {
    static var readableContentTypes: [UTType] { UTType.hangyeolReadableTypes }
    static var writableContentTypes: [UTType] { [.hangyeolHwpx] }

    var model: DocumentModel
    /// Shared across FileDocument copies of this window; not `EngineClient.current`.
    var session: DocumentSession
    /// Set when the display model changes via engine replace or cell edit.
    var hasUnsavedEdits: Bool

    init(model: DocumentModel = .empty, session: DocumentSession? = nil) {
        self.model = model
        self.session = session ?? DocumentSession()
        self.hasUnsavedEdits = false
    }

    init(configuration: ReadConfiguration) throws {
        let type = Self.fileType(from: configuration.contentType)
        guard let data = configuration.file.regularFileContents else {
            throw HangyeolError.emptyFile
        }
        let session = DocumentSession()
        do {
            var model = try session.open(data: data, type: type)
            if model.metadata.title.isEmpty {
                model.metadata.title = configuration.file.filename.map {
                    URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
                } ?? L10n.untitled
            }
            self.model = model
            self.session = session
            self.hasUnsavedEdits = false
        } catch let error as HangyeolError {
            throw error
        } catch {
            throw HangyeolError.mapOpenFailure(error)
        }
    }

    /// FileDocument save: this document's session IR (or Mock JSON), not the process singleton.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try encodedContents(
            as: Self.fileType(from: configuration.contentType)
        ))
    }

    /// Testable save path used by `fileWrapper`. Throws mapped `HangyeolError` (frontend presents).
    func encodedContents(as type: DocumentFileType) throws -> Data {
        try session.save(model, as: type)
    }

    /// Apply Kit `replaceText` on **this** document's live session and refresh the display model.
    mutating func replaceText(find: String, replace: String) throws -> Int {
        let count = try session.replaceText(find: find, replace: replace)
        model = try session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        )
        hasUnsavedEdits = true
        return count
    }

    /// Kit `listTables` on **this** document's live session (`TableInfo.index` for `setCellText`).
    func listTables() throws -> [TableInfo] {
        try session.listTables()
    }

    /// Apply Kit `setCellText` on **this** document's live session and refresh the display model.
    mutating func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        try session.setCellText(table: table, row: row, col: col, text: text)
        model = try session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        )
        hasUnsavedEdits = true
    }

    private static func fileType(from contentType: UTType) -> DocumentFileType {
        if contentType.conforms(to: .hangyeolHwp) || contentType.identifier == UTType.hangyeolHwp.identifier {
            return .hwp
        }
        return .hwpx
    }
}

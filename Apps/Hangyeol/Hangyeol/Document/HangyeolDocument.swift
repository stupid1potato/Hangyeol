import SwiftUI
import UniformTypeIdentifiers

struct HangyeolDocument: FileDocument {
    static var readableContentTypes: [UTType] { UTType.hangyeolReadableTypes }
    static var writableContentTypes: [UTType] { [.hangyeolHwpx] }

    var model: DocumentModel
    /// Shared across FileDocument copies of this window; not `EngineClient.current`.
    var session: DocumentSession
    /// Set when the display model changes via engine replace, cell edit, or paragraph insert/delete.
    var hasUnsavedEdits: Bool

    init(model: DocumentModel = .empty, session: DocumentSession? = nil) {
        self.model = model
        self.session = session ?? DocumentSession()
        self.hasUnsavedEdits = false
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw HangyeolError.emptyFile
        }
        try self.init(
            opening: data,
            type: Self.fileType(from: configuration.contentType),
            filename: configuration.file.filename
        )
    }

    /// Same FileDocument open path, from bytes. Tests use this because
    /// `FileDocumentReadConfiguration` has no accessible initializer on current SDK.
    init(opening data: Data, type: DocumentFileType, filename: String? = nil) throws {
        let session = DocumentSession()
        do {
            var model = try session.open(data: data, type: type)
            if model.metadata.title.isEmpty {
                model.metadata.title = filename.map {
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
    /// Successful live edits register on the window `UndoManager` automatically.
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

    /// Kit `listImages` on **this** document's live session (`ImageInfo` IR meta).
    /// Read-only: does not refresh the display model or mark unsaved edits.
    func listImages() throws -> [ImageInfo] {
        try session.listImages()
    }

    /// Apply Kit `setCellText` on **this** document's live session and refresh the display model.
    /// Successful live edits register on the window `UndoManager` automatically.
    mutating func setCellText(table: UInt32, row: UInt32, col: UInt32, text: String) throws {
        try session.setCellText(table: table, row: row, col: col, text: text)
        model = try session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        )
        hasUnsavedEdits = true
    }

    /// Apply Kit `insertText` on **this** document's live session and refresh the display model.
    /// Successful live edits register on the window `UndoManager` automatically.
    mutating func insertText(
        section: UInt32,
        paragraph: UInt32,
        charOffset: UInt32,
        text: String
    ) throws {
        try session.insertText(
            section: section,
            paragraph: paragraph,
            charOffset: charOffset,
            text: text
        )
        model = try session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        )
        hasUnsavedEdits = true
    }

    /// Apply Kit `deleteRange` on **this** document's live session and refresh the display model.
    /// Successful live edits register on the window `UndoManager` automatically.
    mutating func deleteRange(
        section: UInt32,
        paragraph: UInt32,
        charOffset: UInt32,
        count: UInt32
    ) throws {
        try session.deleteRange(
            section: section,
            paragraph: paragraph,
            charOffset: charOffset,
            count: count
        )
        model = try session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        )
        hasUnsavedEdits = true
    }

    /// Re-read the live display model after `UndoManager` undo/redo.
    /// The document window observes `session.undoGeneration` and calls this.
    mutating func refreshAfterUndoRedo() {
        guard session.canEdit else {
            if session.undoManager != nil {
                hasUnsavedEdits = session.hasUndoableEdits
            }
            return
        }
        if let updated = try? session.displayModel(
            type: model.metadata.sourceType,
            title: model.metadata.title
        ) {
            model = updated
        }
        if session.undoManager != nil {
            hasUnsavedEdits = session.hasUndoableEdits
        }
    }

    /// Testable mapping used by FileDocument open/save configuration.
    static func fileType(from contentType: UTType) -> DocumentFileType {
        UTType.hangyeolFileType(from: contentType)
    }
}

/// Tiny window hook: bind DocumentGroup's `UndoManager` and refresh the
/// FileDocument display model after session undo/redo. Not a UI control.
extension View {
    func hangyeolSessionUndo(document: Binding<HangyeolDocument>) -> some View {
        modifier(HangyeolSessionUndoModifier(document: document))
    }
}

private struct HangyeolSessionUndoModifier: ViewModifier {
    @Binding var document: HangyeolDocument
    @Environment(\.undoManager) private var undoManager

    func body(content: Content) -> some View {
        content
            .onAppear { document.session.attachUndoManager(undoManager) }
            .onChange(of: undoManager != nil) { _, _ in
                document.session.attachUndoManager(undoManager)
            }
            .onReceive(document.session.$undoGeneration) { generation in
                guard generation > 0 else { return }
                document.refreshAfterUndoRedo()
            }
    }
}

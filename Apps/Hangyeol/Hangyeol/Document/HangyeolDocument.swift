import SwiftUI
import UniformTypeIdentifiers

struct HangyeolDocument: FileDocument {
    static var readableContentTypes: [UTType] { UTType.hangyeolReadableTypes }
    static var writableContentTypes: [UTType] { [.hangyeolHwpx] }

    var model: DocumentModel

    init(model: DocumentModel = .empty) {
        self.model = model
    }

    init(configuration: ReadConfiguration) throws {
        let type = Self.fileType(from: configuration.contentType)
        guard let data = configuration.file.regularFileContents else {
            throw HangyeolError.emptyFile
        }
        do {
            self.model = try EngineClient.current.open(data: data, type: type)
        } catch let error as HangyeolError {
            throw error
        } catch {
            throw HangyeolError.engineFailed(error.localizedDescription)
        }
        if model.metadata.title.isEmpty {
            model.metadata.title = configuration.file.filename.map {
                URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
            } ?? L10n.untitled
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let type = Self.fileType(from: configuration.contentType)
        do {
            let data = try EngineClient.current.save(model, as: type)
            return FileWrapper(regularFileWithContents: data)
        } catch let error as HangyeolError {
            throw error
        } catch {
            throw HangyeolError.saveFailed(error.localizedDescription)
        }
    }

    private static func fileType(from contentType: UTType) -> DocumentFileType {
        if contentType.conforms(to: .hangyeolHwp) || contentType.identifier == UTType.hangyeolHwp.identifier {
            return .hwp
        }
        return .hwpx
    }
}

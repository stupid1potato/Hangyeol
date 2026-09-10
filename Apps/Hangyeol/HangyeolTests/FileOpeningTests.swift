import UniformTypeIdentifiers
import XCTest
@testable import Hangyeol

final class FileOpeningTests: XCTestCase {
    func testHangyeolSupportsHwpxAndHwpOnly() {
        XCTAssertTrue(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/memo.hwpx")))
        XCTAssertTrue(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/Memo.HWP")))
        XCTAssertFalse(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/notes.txt")))
        XCTAssertFalse(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/slide.pptx")))
    }

    func testReadableTypesIncludeExportedUTIs() {
        let identifiers = Set(UTType.hangyeolReadableTypes.map(\.identifier))
        XCTAssertTrue(identifiers.contains(UTType.hangyeolHwpx.identifier))
        XCTAssertTrue(identifiers.contains(UTType.hangyeolHwp.identifier))
    }

    func testDocumentFileTypeFromURL() {
        XCTAssertEqual(DocumentFileType(url: URL(fileURLWithPath: "/tmp/a.hwpx")), .hwpx)
        XCTAssertEqual(DocumentFileType(url: URL(fileURLWithPath: "/tmp/a.hwp")), .hwp)
        XCTAssertNil(DocumentFileType(url: URL(fileURLWithPath: "/tmp/a.pdf")))
    }

    func testUnsupportedTypeErrorCopy() {
        let error = HangyeolError.unsupportedType("notes.txt")
        XCTAssertTrue(error.localizedDescription.contains("notes.txt"))
        XCTAssertEqual(error.id, "unsupportedType:notes.txt")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    @MainActor
    func testOpenPanelFiltersHangyeolTypes() {
        let panel = FileOpening.makeOpenPanel()
        let identifiers = Set(panel.allowedContentTypes.map(\.identifier))
        XCTAssertTrue(identifiers.contains(UTType.hangyeolHwpx.identifier))
        XCTAssertTrue(identifiers.contains(UTType.hangyeolHwp.identifier))
        XCTAssertTrue(panel.allowsMultipleSelection)
        XCTAssertTrue(panel.canChooseFiles)
        XCTAssertFalse(panel.canChooseDirectories)
        XCTAssertFalse(panel.allowsOtherFileTypes)
        XCTAssertEqual(panel.prompt, L10n.openPrompt)
    }

    @MainActor
    func testNoteOpenedUpdatesRecentsAndClearRemovesThem() throws {
        RecentDocuments.shared.clear()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hangyeol-week2-\(UUID().uuidString).hwpx")
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("sample".utf8)))
        defer {
            try? FileManager.default.removeItem(at: url)
            RecentDocuments.shared.clear()
        }

        RecentDocuments.shared.noteOpened(url)

        XCTAssertEqual(
            RecentDocuments.shared.items.first?.url.standardizedFileURL.path,
            url.standardizedFileURL.path
        )
        XCTAssertEqual(RecentDocuments.shared.items.first?.title, url.lastPathComponent)

        let other = FileManager.default.temporaryDirectory
            .appendingPathComponent("hangyeol-week2-\(UUID().uuidString).hwp")
        XCTAssertTrue(FileManager.default.createFile(atPath: other.path, contents: Data("sample".utf8)))
        defer { try? FileManager.default.removeItem(at: other) }

        RecentDocuments.shared.noteOpened(other)
        XCTAssertEqual(
            RecentDocuments.shared.items.first?.url.standardizedFileURL.path,
            other.standardizedFileURL.path
        )
        XCTAssertTrue(
            RecentDocuments.shared.items.contains {
                $0.url.standardizedFileURL.path == url.standardizedFileURL.path
            }
        )

        RecentDocuments.shared.clear()
        XCTAssertTrue(RecentDocuments.shared.items.isEmpty)
    }
}

import AppKit
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

    func testWrongExtPdfIsUnsupportedByHangyeolUTI() {
        let url = URL(fileURLWithPath: "/tmp/14_wrong_ext_hwpx.pdf")
        XCTAssertFalse(UTType.hangyeolSupports(url: url))
        XCTAssertEqual(
            HangyeolError.unsupportedType(url.lastPathComponent),
            .unsupportedType("14_wrong_ext_hwpx.pdf")
        )
    }

    @MainActor
    func testMappedErrorUsesDedicatedOpenCases() {
        XCTAssertEqual(
            FileOpening.mappedError(HangyeolError.corrupt),
            .corrupt
        )
        XCTAssertEqual(
            FileOpening.mappedError(HangyeolError.encrypted),
            .encrypted
        )
        XCTAssertEqual(
            FileOpening.mappedError(HangyeolError.unsupported),
            .unsupported
        )
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

    func testBookmarkAndAccessRoundTripsTempFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hangyeol-bookmark-\(UUID().uuidString).hwpx")
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("sample".utf8)))
        defer { try? FileManager.default.removeItem(at: url) }

        guard let bookmark = try? SecurityScopedBookmarks.bookmarkAndAccess(url) else {
            throw XCTSkip("security-scoped bookmarks unavailable in this environment")
        }
        let resolved = try SecurityScopedBookmarks.resolve(bookmark)
        XCTAssertEqual(
            resolved.url.standardizedFileURL.path,
            url.standardizedFileURL.path
        )
        XCTAssertTrue(UTType.hangyeolSupports(url: resolved.url))
    }

    func testInfoPlistExportedUTIsMatchSwiftAndLaunchServicesKeys() throws {
        let data = try Data(contentsOf: try SourceTree.infoPlist())
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["LSSupportsOpeningDocumentsInPlace"] as? Bool, true)
        XCTAssertNil(
            plist["UTImportedTypeDeclarations"],
            "Hangyeol owns org.hangyeol.*; do not import a third-party HWP UTI"
        )

        XCTAssertEqual(UTType.hangyeolHwpx.identifier, "org.hangyeol.hwpx")
        XCTAssertEqual(UTType.hangyeolHwp.identifier, "org.hangyeol.hwp")
        XCTAssertEqual(DocumentFileType.hwpx.typeIdentifier, UTType.hangyeolHwpx.identifier)
        XCTAssertEqual(DocumentFileType.hwp.typeIdentifier, UTType.hangyeolHwp.identifier)
        XCTAssertEqual(
            UTType.hangyeolReadableTypes.map(\.identifier),
            [UTType.hangyeolHwpx.identifier, UTType.hangyeolHwp.identifier]
        )

        let expected: [(id: String, ext: String)] = [
            (UTType.hangyeolHwpx.identifier, "hwpx"),
            (UTType.hangyeolHwp.identifier, "hwp"),
        ]

        let documents = try XCTUnwrap(plist["CFBundleDocumentTypes"] as? [[String: Any]])
        XCTAssertEqual(documents.count, expected.count)
        for (index, spec) in expected.enumerated() {
            let doc = documents[index]
            XCTAssertEqual(doc["CFBundleTypeRole"] as? String, "Editor")
            XCTAssertEqual(doc["LSHandlerRank"] as? String, "Owner")
            XCTAssertEqual(doc["LSItemContentTypes"] as? [String], [spec.id])
            XCTAssertEqual(doc["CFBundleTypeExtensions"] as? [String], [spec.ext])
        }

        let exported = try XCTUnwrap(plist["UTExportedTypeDeclarations"] as? [[String: Any]])
        XCTAssertEqual(exported.count, expected.count)
        for (index, spec) in expected.enumerated() {
            let uti = exported[index]
            XCTAssertEqual(uti["UTTypeIdentifier"] as? String, spec.id)
            let tags = try XCTUnwrap(uti["UTTypeTagSpecification"] as? [String: Any])
            XCTAssertEqual(tags["public.filename-extension"] as? [String], [spec.ext])
            let conforms = try XCTUnwrap(uti["UTTypeConformsTo"] as? [String])
            XCTAssertTrue(conforms.contains("public.data"), spec.id)
            XCTAssertTrue(conforms.contains("public.content"), spec.id)
        }
    }

    func testHangyeolSupportsUsesPathExtensionNotBytes() throws {
        XCTAssertFalse(UTType.hangyeolSupports(url: try SourceTree.fixture("14_wrong_ext_hwpx.pdf")))
        XCTAssertTrue(UTType.hangyeolSupports(url: try SourceTree.fixture("16_corrupt_truncated.hwpx")))
        XCTAssertTrue(UTType.hangyeolSupports(url: try SourceTree.fixture("hub_hwpxlib_SimpleTable.hwpx")))
        XCTAssertFalse(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/no-extension")))
        XCTAssertFalse(UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/14_wrong_ext_hwpx.PDF")))
    }

    @MainActor
    func testHandleDropReturnsFalseWhenNoFileURLProviders() {
        XCTAssertFalse(FileOpening.handleDrop(providers: []))
        let text = NSItemProvider(object: "hello" as NSString)
        XCTAssertFalse(FileOpening.handleDrop(providers: [text]))
    }

    @MainActor
    func testOpenAndOpenResolvedGuardUnsupportedExtension() {
        XCTAssertEqual(
            FileOpening.mappedError(HangyeolError.unsupportedType("14_wrong_ext_hwpx.pdf")),
            .unsupportedType("14_wrong_ext_hwpx.pdf")
        )
        XCTAssertFalse(
            UTType.hangyeolSupports(url: URL(fileURLWithPath: "/tmp/14_wrong_ext_hwpx.pdf"))
        )
    }
}

private enum SourceTree {
    static func infoPlist() throws -> URL {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<10 {
            let candidate = dir.appendingPathComponent("Hangyeol/Resources/Info.plist")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        throw XCTSkip("missing Hangyeol/Resources/Info.plist")
    }

    static func fixture(_ filename: String) throws -> URL {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<10 {
            let candidate = dir.appendingPathComponent("fixtures").appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        throw XCTSkip("missing fixtures/\(filename)")
    }
}

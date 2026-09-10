import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// NSOpenPanel, 드래그 앤 드롭, Dock/Finder 열기를 DocumentGroup에 연결합니다.
@MainActor
enum FileOpening {
    private static var openDocumentAction: OpenDocumentAction?

    static func install(openDocument: OpenDocumentAction) {
        openDocumentAction = openDocument
    }

    static func makeOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = UTType.hangyeolReadableTypes
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = false
        panel.isExtensionHidden = false
        panel.title = L10n.openPrompt
        panel.message = L10n.openPanelMessage
        panel.prompt = L10n.openPrompt
        return panel
    }

    static func presentOpenPanel() {
        let panel = makeOpenPanel()
        guard let window = NSApp.keyWindow else {
            panel.begin { response in
                guard response == .OK else { return }
                open(urls: panel.urls)
            }
            return
        }
        panel.beginSheetModal(for: window) { response in
            guard response == .OK else { return }
            open(urls: panel.urls)
        }
    }

    static func open(urls: [URL]) {
        for url in urls {
            open(url: url)
        }
    }

    static func open(url: URL) {
        guard UTType.hangyeolSupports(url: url) else {
            present(HangyeolError.unsupportedType(url.lastPathComponent))
            return
        }

        _ = SecurityScopedBookmarks.startAccessing(url)
        RecentDocuments.shared.noteOpened(url)
        actuallyOpen(url)
    }

    /// 북마크를 풀어 이미 접근을 시작한 URL을 엽니다.
    static func openResolved(url: URL) {
        guard UTType.hangyeolSupports(url: url) else {
            present(HangyeolError.unsupportedType(url.lastPathComponent))
            return
        }
        RecentDocuments.shared.noteOpened(url)
        actuallyOpen(url)
    }

    /// Reopen a path after save. Keeps security-scoped access for the document lifetime.
    static func reopenSaved(url: URL) {
        open(url: url)
    }

    /// Reopen via a security-scoped bookmark (recent documents / sandbox).
    static func reopenSaved(bookmark: Data) throws {
        let resolved = try SecurityScopedBookmarks.resolve(bookmark)
        _ = SecurityScopedBookmarks.startAccessing(resolved.url)
        openResolved(url: resolved.url)
    }

    static func handleDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = FileOpening.fileURL(from: item) else { return }
                Task { @MainActor in
                    FileOpening.open(url: url)
                }
            }
        }
        return true
    }

    private static func actuallyOpen(_ url: URL) {
        if let openDocumentAction {
            Task { @MainActor in
                do {
                    try await openDocumentAction(at: url)
                } catch {
                    present(error)
                }
            }
            return
        }

        // DocumentGroup가 만든 컨트롤러가 준비된 뒤에만 호출됩니다.
        // 새 문서는 NSDocumentController.newDocument 를 쓰지 않습니다.
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error {
                DispatchQueue.main.async {
                    present(error)
                }
            }
        }
    }

    /// Map Kit/engine/open failures onto dedicated `HangyeolError` cases for ErrorSheet.
    static func mappedError(_ error: Error) -> HangyeolError {
        HangyeolError.mapOpenFailure(error)
    }

    static func present(_ error: Error) {
        let hangyeol = mappedError(error)
        NotificationCenter.default.post(name: HangyeolError.presentNotification, object: hangyeol)
    }

    nonisolated private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let url = item as? NSURL {
            return url as URL
        }
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let path = item as? String {
            return URL(fileURLWithPath: path)
        }
        if let path = item as? NSString {
            return URL(fileURLWithPath: path as String)
        }
        return nil
    }
}

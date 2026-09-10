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

        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error {
                DispatchQueue.main.async {
                    present(error)
                }
            }
        }
    }

    static func present(_ error: Error) {
        let hangyeol: HangyeolError
        if let typed = error as? HangyeolError {
            hangyeol = typed
        } else {
            hangyeol = .engineFailed(error.localizedDescription)
        }
        NSApp.presentError(hangyeol)
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

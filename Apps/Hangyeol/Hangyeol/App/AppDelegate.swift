import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var openedFilesThisSession = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
        RecentDocuments.shared.refresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        DispatchQueue.main.async { [weak self] in
            self?.openedFilesThisSession = false
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        !openedFilesThisSession
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    /// Dock 아이콘·Finder에서 연 파일을 DocumentGroup으로 넘기고 최근 문서에 남깁니다.
    func application(_ application: NSApplication, open urls: [URL]) {
        if !urls.isEmpty {
            openedFilesThisSession = true
        }
        FileOpening.open(urls: urls)
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        window.registerForDraggedTypes([.fileURL])
    }
}

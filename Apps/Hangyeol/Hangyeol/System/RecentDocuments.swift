import AppKit
import Combine

@MainActor
final class RecentDocuments: ObservableObject {
    static let shared = RecentDocuments()

    struct Item: Identifiable, Equatable {
        var id: String { url.absoluteString }
        var url: URL
        var title: String
        var bookmark: Data?
    }

    @Published private(set) var items: [Item] = []

    private let defaultsKey = "hangyeol.recentBookmarks"
    private let maxCount = 12

    private init() {
        refresh()
    }

    func refresh() {
        var seen = Set<String>()
        var combined: [Item] = []

        for url in NSDocumentController.shared.recentDocumentURLs {
            let key = url.standardizedFileURL.path
            guard seen.insert(key).inserted else { continue }
            combined.append(
                Item(
                    url: url,
                    title: url.deletingPathExtension().lastPathComponent,
                    bookmark: try? SecurityScopedBookmarks.bookmark(for: url)
                )
            )
        }

        if let stored = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] {
            for data in stored {
                guard let resolved = try? SecurityScopedBookmarks.resolve(data) else { continue }
                let key = resolved.url.standardizedFileURL.path
                guard seen.insert(key).inserted else { continue }
                combined.append(
                    Item(
                        url: resolved.url,
                        title: resolved.url.deletingPathExtension().lastPathComponent,
                        bookmark: data
                    )
                )
            }
        }

        items = Array(combined.prefix(maxCount))
        persistBookmarks()
    }

    func noteOpened(_ url: URL) {
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        refresh()
    }

    func open(_ item: Item) throws {
        var url = item.url
        if let bookmark = item.bookmark {
            let resolved = try SecurityScopedBookmarks.resolve(bookmark)
            url = resolved.url
            if resolved.isStale {
                noteOpened(url)
            }
        }
        SecurityScopedBookmarks.startAccessing(url)
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            SecurityScopedBookmarks.stopAccessing(url)
            if let error {
                DispatchQueue.main.async {
                    NSApp.presentError(error)
                }
            }
        }
    }

    func clear() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        items = []
    }

    private func persistBookmarks() {
        let data = items.compactMap { item -> Data? in
            if let bookmark = item.bookmark { return bookmark }
            return try? SecurityScopedBookmarks.bookmark(for: item.url)
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
